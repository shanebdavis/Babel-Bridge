module BabelBridge

# Each Rule has one or more RuleVariant
# Rules attempt to match each of their Variants in order. The first one to succeed returns true and the Rule succeeds.
class RuleVariant
  attr_accessor :pattern, :rule, :variant_node_class, :delimiter_pattern, :match_delimiter_prepost

  # pattern: Array - the pattern to match
  # rule: Rule instance
  # variant_node_class: RuleVariant class
  def initialize(options = {})
    @pattern = options[:pattern]
    @rule = options[:rule]
    @variant_node_class = options[:variant_node_class]
    raise "variant_node_class required" unless variant_node_class
    @delimiter = options[:delimiter]
  end

  def parser
    @rule.parser
  end

  def root_rule?
    rule.root_rule?
  end

  def delimiter_pattern
    @delimiter_pattern ||= if @delimiter
      PatternElement.new(@delimiter, :rule_variant => self, :delimiter => true) unless @delimiter==// || @delimiter==""
    else
      parser.delimiter_pattern
    end
  end

  # convert the pattern into a set of lamba functions
  def pattern_elements
    @pattern_elements||=pattern.collect { |match| [PatternElement.new(match, :rule_variant => self, :pattern_element => true), delimiter_pattern] }.flatten[0..-2]
  end

  def parse_element(element_parser, node)
    node.add_match element_parser.parse(node), element_parser.name
  end

  # returns a Node object if it matches, nil otherwise
  def parse(parent_node)
    #return parse_nongreedy_optional(src,offset,parent_node) # nongreedy optionals break standard PEG
    node = variant_node_class.new(parent_node, delimiter_pattern)

    node.match parser.delimiter_pattern if root_rule?

    pattern_elements.each do |pe|
      return unless node.match(pe)
    end
    node.pop_match if node.last_match && node.last_match.delimiter

    node.match parser.delimiter_pattern if root_rule?

    node && node.post_match_processing
  end

  def inspect; pattern.collect {|a| a.inspect}.join(', '); end
  def to_s; "variant_class: #{variant_node_class}, pattern: #{inspect}"; end
end
end
