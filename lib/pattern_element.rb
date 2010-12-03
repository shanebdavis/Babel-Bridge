=begin
Copyright 2010 Shane Brinkman-Davis
See README for licence information.
http://babel-bridge.rubyforge.org/
=end

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

      self.parser = lambda {|parent_node| match_rule.parse(parent_node)}
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
end