=begin
Copyright 2010 Shane Brinkman-Davis
See README for licence information.
http://babel-bridge.rubyforge.org/
=end

module BabelBridge

# PatternElement provides optimized parsing for each Element of a pattern
# PatternElement provides all the logic for parsing:
#   :many
#   :optional
class PatternElement
  attr_accessor :parser, :optional, :negative, :name, :terminal, :could_match
  attr_accessor :match, :rule_variant, :parser_class

  # true if this is a delimiter
  attr_accessor :delimiter

  #match can be:
  # true, Hash, Symbol, String, Regexp
  # options
  #   :rule_varient
  #   :parser
  def initialize(match, options={})
    @init_options = options.clone
    @rule_variant = options[:rule_variant]
    @parser_class = options[:parser_class]
    @delimiter = options[:delimiter]
    @name = options[:name]
    raise "rule_variant or parser_class required" unless @rule_variant || @parser_class

    init match
    raise "pattern element cannot be both :dont and :optional" if negative && optional
  end

  def inspect
    "<PatternElement #{rule_variant && "rule_variant=#{rule_variant.variant_node_class} "}match=#{match.inspect}#{" delimiter" if delimiter}>"
  end

  def to_s
    match.inspect
  end

  def parser_class
    @parser_class || rule_variant.rule.parser
  end

  def rules
    parser_class.rules
  end

  # attempt to match the pattern defined in self.parser in parent_node.src starting at offset parent_node.next
  def parse(parent_node)

    # run element parser
    begin
      parent_node.parser.matching_negative if negative
      match = parser.call(parent_node)
    ensure
      parent_node.parser.unmatching_negative if negative
    end

    # Negative patterns (PEG: !element)
    match = match ? nil : EmptyNode.new(parent_node) if negative

    # Optional patterns (PEG: element?)
    match = EmptyNode.new(parent_node) if !match && optional

    # Could-match patterns (PEG: &element)
    match.match_length = 0 if match && could_match

    if !match && (terminal || negative)
      # log failures on Terminal patterns for debug output if overall parse fails
      parent_node.parser.log_parsing_failure parent_node.next, :pattern => self.to_s, :node => parent_node
    end

    match.delimiter = delimiter if match

    # return match
    match
  end

  private

  # initialize PatternElement based on the type of: match
  def init(match)
    self.match = match
    match = match[0] if match.kind_of?(Array) && match.length == 1
    case match
    when String then    init_string match
    when Regexp then    init_regex match
    when Symbol then    init_rule match
    when PatternElementHash then      init_hash match
    when Array then     init_array match
    else                raise "invalid pattern type: #{match.inspect}"
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
      offset = parent_node.next
      if parent_node.src[offset..-1].index(optimized_regex)==0
        range = $~.offset(0)
        range = (range.min+offset)..(range.max+offset)
        TerminalNode.new(parent_node,range,regex)
      end
    end
    self.terminal=true
  end

  # initialize PatternElement as a parser that matches a named sub-rule
  def init_rule(rule_name)
    rule_name.to_s[/^([^?!]*)([?!])?$/]
    rule_name = $1.to_sym
    option = $2
    match_rule = rules[rule_name]
    raise "no rule for #{rule_name}" unless match_rule

    self.parser = lambda {|parent_node| match_rule.parse(parent_node)}
    self.name ||= rule_name
    case option
    when "?"  then self.optional = true
    when "!"  then self.negative = true
    end
  end

  def init_any(patterns)
    patterns = patterns.collect {|p| PatternElement.new(p,@init_options)}
    self.parser = lambda do |parent_node|
      patterns.each do |p|
        node = p.parse(parent_node)
        return node if node
      end
      nil
    end
  end

  def init_array(patterns)
    patterns = patterns.collect {|p| PatternElement.new(p,@init_options)}
    self.parser = lambda do |parent_node|
      parent_node.attempt_match do
        patterns.each do |p|
          return nil unless parent_node.match p
        end
      end
      parent_node
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
    elsif hash[:any]
      init_any hash[:any]
    else
      raise "extended-options patterns (specified by a hash) must have either :parser=> or a :match=> set"
    end

    self.name = hash[:as] || self.name
    self.optional ||= hash[:optional] || hash[:optionally]
    self.could_match ||= hash[:could]
    self.negative ||= hash[:dont]
  end

  # initialize the PatternElement as a many-parser from hashed parameters (hash[:many] is assumed to be set)
  def init_many(hash)
    # generate single_parser
    pattern_element = PatternElement.new(hash[:many], @init_options.merge(name:hash[:as]))

    # generate delimiter_pattern_element
    many_delimiter_pattern_element = hash[:delimiter] && PatternElement.new(hash[:delimiter], @init_options.merge(name:hash[:delimiter_name]))

    # generate many-parser
    self.parser = lambda do |parent_node|
      parent_node.match_name_is_poly(pattern_element.name)

      # fail unless we can match at least one
      return unless parent_node.match pattern_element

      if many_delimiter_pattern_element
        parent_node.match_name_is_poly(many_delimiter_pattern_element.name)
        # delimited matching
        while (parent_node.attempt_match do
            parent_node.match_delimiter &&
            parent_node.match(many_delimiter_pattern_element).tap{|md|md&&md.many_delimiter=true} &&
            parent_node.match_delimiter &&
            parent_node.match(pattern_element)
          end)
        end
      else
        # not delimited matching
        while (parent_node.attempt_match do
            parent_node.match_delimiter &&
            parent_node.match(pattern_element)
          end)
        end
      end
      parent_node
    end
  end
end
end
