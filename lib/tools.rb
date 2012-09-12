module BabelBridge
class Tools
  class << self

    # Takes an array of Strings and Regexp and generates a new Regexp 
    # that matches the or ("|") of all strings and Regexp
    def array_to_or_regexp(array)
      new_re=array.flatten.collect do |op|
        "("+case op
        when Regexp then op.source
        when String, Symbol then Regexp.escape(op.to_s)
        end+")"
      end.join('|')
      Regexp.new new_re
    end
  end
end

class BinaryOperatorProcessor
  attr_accessor :node_class, :exact_operator_precedence, :regexp_operator_precedence
  def initialize(operator_precedence,node_class)
    @node_class=node_class
    @exact_operator_precedence={}
    @regexp_operator_precedence=[]

    operator_precedence.each_with_index do |op_level,i|
      (op_level.kind_of?(Array) ? op_level : [op_level]).each do |op|
        case op
        when String, Symbol then @exact_operator_precedence[op.to_s] = i
        when Regexp then @regexp_operator_precedence << [op,i]
        end
      end
    end
  end

  def operator_precedence(operator_string)
    p = @exact_operator_precedence[operator_string]
    return p if p
    @regexp_operator_precedence.each do |regexp,p|
      return p if operator_string[regexp]
    end
    raise "operator #{operator_string.inspect} didn't match #{@exact_operator_precedence} or #{@regexp_operator_precedence}"
  end

  # associativity =
  #    :left => operators of the same precidence execut from left to right
  #    :right => operators of the same precidence execut from right to left
  def index_of_lowest_precedence(operators,associativity=:left)
    lowest = lowest_precedence = nil
    operators.each_with_index do |operator,i|
      precedence = operator_precedence(operator.to_s)
      if !lowest || (associativity==:left ? precedence <= lowest_precedence : precedence < lowest_precedence)
        lowest = i
        lowest_precedence = precedence
      end
    end
    lowest
  end

  # generates a tree of nodes of the specified node_class
  # The nodes have access to the following useful methods:
  #    self.left -> return the left operand parse-tree-node
  #    self.right -> return the right operand parse-tree-node
  #    self.operator_node -> return the operator parse-tree-node
  #    self.operator -> return the operator as a ruby symbol
  def generate_tree(operands, operators, parent_node)
    return operands[0] if operands.length==1

    i = index_of_lowest_precedence(operators)

    operator = operators[i]
    new_operand = node_class.new(parent_node)
    new_operand.add_match generate_tree(operands[0..i], operators[0..i-1],new_operand), :left
    new_operand.add_match operators[i], :operator_node
    new_operand.add_match generate_tree(operands[i+1..-1], operators[i+1..-1],new_operand), :right
    new_operand
  end

end
end