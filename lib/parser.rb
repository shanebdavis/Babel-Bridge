module BabelBridge
# primary object used by the client
# Used to generate the grammer with .rule methods
# Used to parse with .parse
class Parser

  # Parser sub-class grammaer definition
  # These methods are used in the creation of a Parser Sub-Class to define
  # its grammar
  class <<self
    attr_accessor :rules,:module_name,:root_rule

    def rules
      @rules||={}
    end

    # Add a rule to the parser
    #
    # rules can be specified as:
    #   rule :name, to_match1, to_match2, etc...
    #or
    #   rule :name, [to_match1, to_match2, etc...]
    #
    # Can define rules INSIDE class:
    #   class MyParser < BabelBridge::Parser
    #     rule :name, to_match1, to_match2, etc...
    #   end
    #
    # Or can define rules OUTSIDE class:
    #   class MyParser < BabelBridge::Parser
    #   end
    #   MyParser.rule :name, to_match1, to_match2, etc...
    #
    # The first rule added is the root-rule for the parser.
    # You can override by: 
    #   class MyParser < BabelBridge::Parser
    #     root_rule = :new_root_rool
    #   end
    #
    # The block is executed in the context of the rule-varient's node type, a subclass of: NonTerminalNode
    # This allows you to add whatever functionality you want to a your nodes in the final parse tree.
    # Also note you can override the post_match method. This allows you to restructure the parse tree as it is parsed.
    def rule(name,*pattern,&block)
      pattern=pattern[0] if pattern[0].kind_of?(Array)
      rule=self.rules[name]||=Rule.new(name,self)
      self.root_rule||=name
      rule.add_variant(pattern,&block)
    end

    def binary_operators_rule(name,elements_pattern,operators,&block)
      rule(name,many(elements_pattern,Tools::array_to_or_regexp(operators))) do 
        self.class_eval &block if block
        class <<self
          attr_accessor :operators_from_rule
          def operator_processor
            @operator_processor||=BinaryOperatorProcessor.new(operators_from_rule,self)
          end
        end
        self.operators_from_rule=operators

        def operator
          @operator||=operator_node.to_s.to_sym
        end

        # Override the post_match method to take the results of the "many" match
        # and restructure it into a binary tree of nodes based on the precidence of
        # the "operators".
        # TODO - I think maybe post_match should be run after the whole tree matches. If not, will this screw up caching?
        def post_match
          many_match = matches[0]
          operands = many_match.matches
          operators = many_match.delimiter_matches
          # TODO - now! take many_match.matches and many_match.delimiter_matches, mishy-mashy, and make the super-tree!
          self.class.operator_processor.generate_tree operands, operators, parent
        end
      end
    end

    def node_class(name,&block)
      klass=self.rules[name].node_class
      return klass unless block
      klass.class_eval &block
    end

    def [](i)
      rules[i]
    end

    # rule can be symbol-name of one of the rules in rules_array or one of the actual Rule objects in that array
    def root_rule=(rule)
      raise "Symbol required" unless rule.kind_of?(Symbol)
      raise "rule #{rule.inspect} not found" unless rules[rule]
      @root_rule=rule
    end

    def ignore_whitespace
      @ignore_whitespace = true
    end

    def ignore_whitespace?
      @ignore_whitespace
    end
  end

  def ignore_whitespace?
    self.class.ignore_whitespace?
  end

  #*********************************************
  # pattern construction tools
  #
  # Ex:
  #   # match 'keyword'
  #   # (succeeds if keyword is matched; advances the read pointer)
  #   rule :sample_rule, "keyword"
  #   rule :sample_rule, match("keyword")
  #
  #   # don't match 'keyword'
  #   # (succeeds only if keyword is NOT matched; does not advance the read pointer)
  #   rule :sample_rule, match!("keyword")
  #   rule :sample_rule, dont.match("keyword")
  #
  #   # optionally match 'keyword'
  #   # (always succeeds; advances the read pointer if keyword is matched)
  #   rule :sample_rule, match?("keyword")
  #   rule :sample_rule, optionally.match("keyword")
  #
  #   # ensure we could match 'keyword'
  #   # (succeeds only if keyword is matched, but does not advance the read pointer)
  #   rule :sample_rule, could.match("keyword")
  #
  #*********************************************
  class <<self
    def many(m,delimiter=nil,post_delimiter=nil) PatternElementHash.new.match.many(m).delimiter(delimiter).post_delimiter(post_delimiter) end
    def many?(m,delimiter=nil,post_delimiter=nil) PatternElementHash.new.optionally.match.many(m).delimiter(delimiter).post_delimiter(post_delimiter) end
    def many!(m,delimiter=nil,post_delimiter=nil) PatternElementHash.new.dont.match.many(m).delimiter(delimiter).post_delimiter(post_delimiter) end

    def match?(*args) PatternElementHash.new.optionally.match(*args) end
    def match(*args) PatternElementHash.new.match(*args) end
    def match!(*args) PatternElementHash.new.dont.match(*args) end

    def dont; PatternElementHash.new.dont end
    def optionally; PatternElementHash.new.optionally end
    def could; PatternElementHash.new.could end
  end


  #*********************************************
  #*********************************************
  # parser instance implementation
  # this methods are used for each actual parse run
  # they are tied to an instnace of the Parser Sub-class to you can have more than one
  # parser active at a time
  attr_accessor :failure_index
  attr_accessor :expecting_list
  attr_accessor :src
  attr_accessor :parse_cache

  def initialize
    reset_parser_tracking
  end

  def reset_parser_tracking
    self.src=nil
    self.failure_index=0
    self.expecting_list={}
    self.parse_cache={}
  end

  def cached(rule_class,offset)
    (parse_cache[rule_class]||={})[offset]
  end

  def cache_match(rule_class,match)
    (parse_cache[rule_class]||={})[match.offset]=match
  end

  def cache_no_match(rule_class,offset)
    (parse_cache[rule_class]||={})[offset]=:no_match
  end

  def log_parsing_failure(index,expecting)
    if index>failure_index
      key=expecting[:pattern]
      @expecting_list={key=>expecting}
      @failure_index = index
    elsif index == failure_index
      key=expecting[:pattern]
      self.expecting_list[key]=expecting
    else
      # ignored
    end
  end

  def parse(src,offset=0,rule=nil)
    reset_parser_tracking
    @start_time=Time.now
    self.src=src
    root_node=RootNode.new(self)
    raise "No root rule defined." unless rule || self.class.root_rule
    ret=self.class[rule||self.class.root_rule].parse(root_node)
    unless rule
      if ret
        if ret.next<src.length # parse only succeeds if the whole input is matched
          @parsing_did_not_match_entire_input=true
          @failure_index=ret.next
          ret=nil
        else
          reset_parser_tracking
        end
      end
    end
    @end_time=Time.now
    ret
  end

  def parse_time
    @end_time-@start_time
  end

  def parse_and_puts_errors(src,out=$stdout)
    ret=parse(src)
    unless ret
      out.puts parser_failure_info
    end
    ret
  end

  def node_list_string(node_list,common_root=[])
    node_list && node_list[common_root.length..-1].map{|p|"#{p.class}(#{p.offset})"}.join(" > ")
  end

  def parser_failure_info
    return unless src
    bracketing_lines=5
    line,col=src.line_col(failure_index)
    ret=<<-ENDTXT
Parsing error at line #{line} column #{col} offset #{failure_index}

Source:
...
#{(failure_index==0 ? "" : src[0..(failure_index-1)]).last_lines(bracketing_lines)}<HERE>#{src[(failure_index)..-1].first_lines(bracketing_lines)}
...
ENDTXT

      if @parsing_did_not_match_entire_input
        ret+="\nParser did not match entire input."
      else

        common_root=nil
        expecting_list.values.each do |e|
          node=e[:node]
          pl=node.parent_list
          if common_root
            common_root.each_index do |i|
              if pl[i]!=common_root[i]
                common_root=common_root[0..i-1]
                break
              end
            end
          else
            common_root=node.parent_list
          end
        end
        ret+=<<ENDTXT

Successfully matched rules up to failure:
  #{node_list_string(common_root)}

Expecting#{expecting_list.length>1 ? ' one of' : ''}:
  #{expecting_list.values.collect do |a|
    list=node_list_string(a[:node].parent_list,common_root)
    [list,"#{a[:pattern].inspect} (#{list})"]
  end.sort.map{|i|i[1]}.join("\n  ")}
ENDTXT
    end
    ret
  end
end
end