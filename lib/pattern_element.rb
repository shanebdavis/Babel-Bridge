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
    raise "More than one argument is not supported. #{self.class}##{method_name} args=#{args.inspect}" if args.length > 1
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
  attr_accessor :match,:rule_variant,:rewind_whitespace

  #match can be:
  # true, Hash, Symbol, String, Regexp
  def initialize(match,rule_variant)
    self.rule_variant=rule_variant
    init(match)

    raise "pattern element cannot be both :dont and :optional" if negative && optional
  end

  def inspect
    "<PatternElement rule_variant=#{rule_variant.variant_node_class} match=#{match.inspect}>"
  end

  def to_s
    match.inspect
  end

  # attempt to match the pattern defined in self.parser in parent_node.src starting at offset parent_node.next
  def parse(parent_node)
    # run element parser
    match=parser.call(parent_node)

    # Negative patterns (PEG: !element)
    match=match ? nil : EmptyNode.new(parent_node) if negative

    # Optional patterns (PEG: element?)
    match=EmptyNode.new(parent_node) if !match && optional

    # Could-match patterns (PEG: &element)
    match.match_length=0 if match && could_match

    if !match && terminal
      # log failures on Terminal patterns for debug output if overall parse fails
      parent_node.parser.log_parsing_failure(match_start_index(parent_node),:pattern=>self.match,:node=>parent_node)
    end

    # return match
    match
  end

  private

  # initialize PatternElement based on the type of: match
  def init(match)
    self.match=match
    case match
    when TrueClass then init_true
    when String then    init_string match
    when Regexp then    init_regex match
    when Symbol then    init_rule match
    when Hash then      init_hash match
    else                raise "invalid pattern type: #{match.inspect}"
    end
  end

  # "true" parser always matches the empty string
  def init_true
    self.parser=lambda {|parent_node| EmptyNode.new(parent_node)}
  end

  def match_start_index(parent_node)
    if rewind_whitespace
      parent_node.trailing_whitespace_range.first
    else
      parent_node.next
    end
  end


  # initialize PatternElement as a parser that matches exactly the string specified
  def init_string(string)
    init_regex Regexp.escape(string)
  end

  # initialize PatternElement as a parser that matches the given regex
  def init_regex(regex)
    optimized_regex=/\A#{regex}/  # anchor the search
    self.parser=lambda do |parent_node|
      offset = match_start_index(parent_node)
      if parent_node.src[offset..-1].index(optimized_regex)==0
        range=$~.offset(0)
        range = (range.min+offset)..(range.max+offset)
        TerminalNode.new(parent_node,range,regex)
      end
    end
    self.terminal=true
  end

  # initialize PatternElement as a parser that matches a named sub-rule
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

  # initialize the PatternElement from hashed parameters
  def init_hash(hash)
    if hash[:parser]
      self.parser=hash[:parser]
    elsif hash[:many]
      init_many hash
    elsif hash[:match]
      init hash[:match]
    else
      raise "extended-options patterns (specified by a hash) must have either :parser=> or a :match=> set"
    end

    self.name = hash[:as] || self.name
    self.optional ||= hash[:optional] || hash[:optionally]
    self.could_match ||= hash[:could]
    self.negative ||= hash[:dont]
    self.rewind_whitespace ||= hash[:rewind_whitespace]
  end

  # initialize the PatternElement as a many-parser from hashed parameters (hash[:many] is assumed to be set)
  def init_many(hash)
    # generate single_parser
    init hash[:many]
    single_parser=parser

    # generate delimiter_pattern_element
    delimiter_pattern_element= hash[:delimiter] && PatternElement.new(hash[:delimiter],rule_variant)

    # generate post_delimiter_element
    post_delimiter_element=hash[:post_delimiter] && case hash[:post_delimiter]
    when TrueClass then delimiter_pattern_element
    else PatternElement.new(hash[:post_delimiter],rule_variant)
    end

    # generate many-parser
    self.parser= lambda do |parent_node|
      last_match=single_parser.call(parent_node)
      many_node=ManyNode.new(parent_node)

      if delimiter_pattern_element
        # delimited matching
        while last_match
          many_node<<last_match

          #match delimiter
          delimiter_match = delimiter_pattern_element.parse(many_node)
          break unless delimiter_match
          many_node.delimiter_matches<<delimiter_match

          #match next
          last_match=single_parser.call(many_node)
        end
      else
        # not delimited matching
        while last_match
          many_node<<last_match
          last_match=single_parser.call(many_node)
        end
      end

      # success only if we have at least one match
      return nil unless many_node.length>0

      # pop the post delimiter matched with delimiter_pattern_element
      many_node.delimiter_matches.pop if many_node.length==many_node.delimiter_matches.length

      # If post_delimiter is requested, many_node and delimiter_matches will be the same length
      if post_delimiter_element
        post_delimiter_match=post_delimiter_element.parse(many_node)

        # fail if post_delimiter didn't match
        return nil unless post_delimiter_match
        many_node.delimiter_matches<<post_delimiter_match
      end

      many_node
    end
  end
end
end
