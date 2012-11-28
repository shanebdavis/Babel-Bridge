module BabelBridge

# Each Rule has one or more RuleVariant
# Rules attempt to match each of their Variants in order. The first one to succeed returns true and the Rule succeeds.
class RuleVariant
  attr_accessor :pattern, :rule, :variant_node_class

  def initialize(pattern, rule, variant_node_class=nil)
    @pattern = pattern
    @rule = rule
    @variant_node_class = variant_node_class
  end

  # convert the pattern into a set of lamba functions
  def pattern_elements
    @pattern_elements||=pattern.collect { |match| PatternElement.new match, self }
  end

  # returns a Node object if it matches, nil otherwise
  def parse(parent_node)
    #return parse_nongreedy_optional(src,offset,parent_node) # nongreedy optionals break standard PEG
    node = variant_node_class.new(parent_node)

    pattern_elements.each do |pe|
      match=pe.parse(node)

      # if parse failed
      return if !match
      match.matched

      # parse succeeded, add to node and continue
      node.add_match(match,pe.name)
    end
    node.post_match
  end

  def inspect; pattern.collect {|a| a.inspect}.join(', '); end
  def to_s; "variant_class: #{variant_node_class}, pattern: #{inspect}"; end
end
end
