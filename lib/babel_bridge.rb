=begin

See README

TODO-FEATURE: :pre_delimiter option
TODO-FEATURE: The "expecting" feature is so good I wonder if we should add the ability to automatically repair the parse!
  This would need:
    a) default values for regex termainals (string terminals are their own default values)
      default values for regex should be verified to match the regex
    b) an interactive prompter if there is more than one option

TODO-IMPROVEMENT: "Expecting" should show line numbers instead of char numbers, but it should only calculated
  on demand. This means we need a smarter formatter for our possible-error-logging.
TODO-IMPROVEMENT: "Expecting" code lines dump should show line numbers

TODO-BUG: "Expecting" doesn't do the right thing of a "dont" clause matched
  Should say "something other than #{the don't clause}"
  Ideally, we would continue matching and list all the possible next clauses that would allow us to continue

IDEA: could use the "-" prefix operator to mean "dont":
  -"this"
  -:that
  -match(:foo)
  -many(:foo)

TODO-OPTIMIZATION: add memoizing (caching / dynamic-programming) to guarantee linear time parsing
  http://en.wikipedia.org/wiki/Parsing_expression_grammar#Implementing_parsers_from_parsing_expression_grammars
=end

require File.dirname(__FILE__) + "/nodes.rb"

class String
  def camelize
    self.split("_").collect {|a| a.capitalize}.join
  end

  def first_lines(n)
    lines=self.split("\n",-1)
    lines.length<=n ? self : lines[0..n-1].join("\n")
  end

  def last_lines(n)
    lines=self.split("\n",-1)
    lines.length<=n ? self : lines[-n..-1].join("\n")
  end

  def line_col(offset)
    lines=self[0..offset-1].split("\n")
    return lines.length, lines[-1].length
  end
end

module BabelBridge

  # hash which can be used declaratively
  class PatternElementHash < Hash
    def method_missing(method_name, *args)  #method_name is a symbol
      return self if args.length==1 && !args[0] # if nil is provided, don't set anything
      self[method_name]=args[0] || true # on the other hand, if no args are provided, assume true
      self
    end
  end

  # PatternElement provides optimized parsing for each Element of a pattern
  # PatternElement provides all the logic for parsing:
  #   :many
  #   :optional
  class PatternElement
    attr_accessor :parser,:optional,:negative,:name,:terminal,:could_match
    attr_accessor :match,:rule_variant

    #match can be:
    # true, Hash, Symbol, String, Regexp
    def initialize(match,rule_variant)
      self.rule_variant=rule_variant
      init(match)

      raise "pattern element cannot be both :dont and :optional" if negative && optional
    end

    def to_s
      match.inspect
    end

    def parse(parent_node)
      # run element parser
      match=parser.call(parent_node)

      # Negative patterns (PEG: !element)
      match=match ? nil : EmptyNode.new(parent_node) if negative

      # Optional patterns (PEG: element?)
      match=EmptyNode.new(parent_node) if !match && optional

      # Could-match patterns (PEG: &element)
      match.match_length=0 if match && could_match

      # return match
      match
    end

    private

    def init(match)
      self.match=match
      case match
      when TrueClass then init_true
      when Hash then      init_hash match
      when Symbol then    init_rule match
      when String then    init_string match
      when Regexp then    init_regex match
      else                raise "invalid pattern type: #{match.inspect}"
      end
    end

    def init_rule(rule_name)
      rule_name.to_s[/^([^?!]*)([?!])?$/]
      rule_name=$1.to_sym
      option=$2
      match_rule=rule_variant.rule.parser.rules[rule_name]
      raise "no rule for #{rule_name}" unless match_rule

      self.parser =lambda {|parent_node| match_rule.parse(parent_node)}
      self.name   = rule_name
      case option
      when "?"  then self.optional=true
      when "!"  then self.negative=true
      end
    end

    def init_hash(hash)
      if hash[:parser]
        self.parser=hash[:parser]
      elsif hash[:many]
        init hash[:many]
        #generate parser for poly
        delimiter_pattern_element= PatternElement.new(hash[:delimiter]||true,rule_variant)

        post_delimiter_element=case hash[:post_delimiter]
          when TrueClass then delimiter_pattern_element
          when nil then nil
          else PatternElement.new(hash[:post_delimiter],rule_variant)
          end

        # convert the single element parser into a poly-parser
        single_parser=parser
        self.parser= lambda do |parent_node|
          last_match=single_parser.call(parent_node)
          many_node=ManyNode.new(parent_node)
          while last_match
            many_node<<last_match

            #match delimiter
            delimiter_match=delimiter_pattern_element.parse(many_node)
            break unless delimiter_match
            many_node.delimiter_matches<<delimiter_match

            #match next
            last_match=single_parser.call(many_node)
          end

          # success only if we have at least one match
          return nil unless many_node.length>0

          # pop the post delimiter matched with delimiter_pattern_element
          many_node.delimiter_matches.pop if many_node.length==many_node.delimiter_matches.length

          # If post_delimiter is requested, many_node and delimiter_matches must be the same length
          if post_delimiter_element
            post_delimiter_match=post_delimiter_element.parse(many_node)

            # fail if post_delimiter didn't match
            return nil unless post_delimiter_match
            many_node.delimiter_matches<<post_delimiter_match
          end

          many_node
        end
      elsif hash[:match]
        init hash[:match]
      else
        raise "extended-options patterns (specified by a hash) must have either :parser=> or a :match=> set"
      end

      self.name = hash[:as] || self.name
      self.optional ||= hash[:optional] || hash[:optionally]
      self.could_match ||= hash[:could]
      self.negative ||= hash[:dont]

    end

    # "true" parser always matches the empty string
    def init_true
      self.parser=lambda {|parent_node| EmptyNode.new(parent_node)}
    end

    # parser that matches exactly the string specified
    def init_string(string)
      self.parser=lambda {|parent_node| parent_node.src[parent_node.next,string.length]==string && TerminalNode.new(parent_node,string.length,string)}
      self.terminal=true
    end

    # parser that matches the given regex
    def init_regex(regex)
      self.parser=lambda {|parent_node| offset=parent_node.next;parent_node.src.index(regex,offset)==offset && (o=$~.offset(0)) && TerminalNode.new(parent_node,o[1]-o[0],regex)}
      self.terminal=true
    end

  end


  # Each Rule has one or more RuleVariant
  # Rules attempt to match each of their Variants in order. The first one to succeed returns true and the Rule succeeds.
  class RuleVariant
    attr_accessor :pattern,:rule,:node_class

    def initialize(pattern,rule,node_class=nil)
      self.pattern=pattern
      self.rule=rule
      self.node_class=node_class
    end

    def inspect
      pattern.collect{|a|a.inspect}.join(', ')
    end

    def to_s
      "variant_class: #{node_class}, pattern: #{inspect}"
    end

    # convert the pattern into a set of lamba functions
    def pattern_elements
      @pattern_elements||=pattern.collect { |match| PatternElement.new match, self }
    end

    # returns a Node object if it matches, nil otherwise
    def parse(parent_node)
      #return parse_nongreedy_optional(src,offset,parent_node) # nongreedy optionals break standard PEG
      node=node_class.new(parent_node)

      pattern_elements.each do |pe|
        match=pe.parse(node)

        # if parse failed
        if !match
          if pe.terminal
            # log failures on Terminal patterns for debug output if overall parse fails
            node.parser.log_parsing_failure(node.next,:pattern=>pe.match,:node=>node)
          end
          return nil
        end

        # parse succeeded, add to node and continue
        node.add_match(match,pe.name)
      end
      node
    end
  end

  # Rules define one or more patterns (RuleVariants)  to match for a given non-terminal
  class Rule
    attr_accessor :name,:variants,:parser,:node_class

    def initialize(name,parser)
      self.name=name
      self.variants=[]
      self.parser=parser

      class_name = "#{parser.module_name}_#{name}_node".camelize
      self.node_class = parser.const_set(class_name,Class.new(NodeNT))
    end

    def add_variant(pattern, &block)

      rule_variant_class_name = "#{name}_node#{self.variants.length+1}".camelize
      rule_variant_class = parser.const_set(rule_variant_class_name,Class.new(node_class))
      self.variants << RuleVariant.new(pattern,self,rule_variant_class)
      rule_variant_class.class_eval &block if block
      rule_variant_class
    end

    def parse(node)
      if cached=node.parser.cached(name,node.next)
        return cached==:no_match ? nil : cached # return nil if cached==:no_matched
      end

      variants.each do |v|
        match=v.parse(node)
        if match
          node.parser.cache_match(name,match)
          return match
        end
      end
      node.parser.cache_no_match(name,node.next)
      nil
    end

    # inspect returns a string which approximates the syntax for generating the rule and all its variants
    def inspect
      variants.collect do |v|
        "rule #{name.inspect}, #{v.inspect}"
      end.join("\n")
    end

    # returns a more human-readable explanation of the rule
    def to_s
      "rule #{name.inspect}, node_class: #{node_class}\n\t"+
      "#{variants.collect {|v|v.to_s}.join("\n\t")}"
    end
  end

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
      # rules can be specified as:
      #   parser.rule :name, to_match1, to_match2, etc...
      #or
      #   parser.rule :name, [to_match1, to_match2, etc...]
      def rule(name,*pattern,&block)
        pattern=pattern[0] if pattern[0].kind_of?(Array)
        rule=self.rules[name]||=Rule.new(name,self)
        self.root_rule||=name
        rule.add_variant(pattern,&block)
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

    #   dont.match("keyword") #
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

