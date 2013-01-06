module BabelBridge
# Rules define one or more patterns (RuleVariants)  to match for a given non-terminal
class Rule
  attr_accessor :name, :variants, :parser, :node_class

  private
  # creates a subclass of the RuleNode for this Rule's node_class
  def create_node_class
    class_name = "#{parser.module_name}_#{name}_node".camelize
    parser.const_set class_name, Class.new(RuleNode)
  end

  # creates a new sub_class of the node_class for a variant
  def new_variant_node_class
    rule_variant_class_name = "#{name}_node#{self.variants.length+1}".camelize
    parser.const_set rule_variant_class_name, Class.new(node_class)
  end

  public
  def initialize(name,parser)
    @name = name
    @variants = []
    @parser = parser
    @node_class = create_node_class
  end

  def root_rule?
    parser.root_rule == name
  end

  def add_variant(options={}, &block)
    new_variant_node_class.tap do |variant_node_class|
      options[:variant_node_class] = variant_node_class
      options[:rule] = self
      variants << RuleVariant.new(options)
      variant_node_class.class_eval &block if block
    end
  end

  def parse(node)
    if cached = node.parser.cached(name,node.next)
      return cached == :no_match ? nil : cached # return nil if cached==:no_matched
    end

    variants.each do |v|
      if match = v.parse(node)
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
end
