module BabelBridge
# Rules define one or more patterns (RuleVariants)  to match for a given non-terminal
class Rule
  attr_accessor :name,:variants,:parser,:node_class

  def initialize(name,parser)
    self.name=name
    self.variants=[]
    self.parser=parser

    class_name = "#{parser.module_name}_#{name}_node".camelize
    self.node_class = parser.const_set(class_name,Class.new(NonTerminalNode))
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
      if match=v.parse(node)
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