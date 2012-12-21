module BabelBridge
class Tools
  class << self

    def indent(string, first_indent = "  ", rest_indent = first_indent)
      first_indent + string.gsub("\n", "\n#{rest_indent}")
    end

    def uniform_tabs(string)
      lines = string.split("\n").collect{|line|line.split("\t")}
      max_fields = lines.collect {|line| line.length}.max
      max_fields.times do |field|
        max_field_length = lines.collect {|line| (line[field]||"").length}.max
        formatter = "%-#{max_field_length}s "
        lines.each_with_index do |line,i|
          lines[i][field] = formatter%line[field] if line[field]
        end
      end
      lines.collect {|line|line.join}.join("\n")
    end

    def symbols_to_strings(array)
      array.collect {|op| op.kind_of?(Symbol) ? op.to_s : op}
    end

    def regexp_and_strings_to_regexpstrings(array)
      array.collect {|op| op.kind_of?(Regexp) ? op.source : Regexp.escape(op)}
    end

    # sort strings first, regexp second
    # sort strings by lenght, longest first
    # will then match first to last
    def sort_operator_patterns(array)
      array.sort_by {|a| a.kind_of?(Regexp) ? 0 : -a.length}
    end

    # Takes an array of Strings and Regexp and generates a new Regexp
    # that matches the or ("|") of all strings and Regexp
    def array_to_or_regexp_string(array)
      array = symbols_to_strings array.flatten
      array = sort_operator_patterns array
      array = regexp_and_strings_to_regexpstrings array

      array.collect {|op| "(#{op})"}.join('|') #.tap {|a| puts "array_to_or_regexp_string(#{array.inspect}) -> /#{a}/"}
    end

    def array_to_anchored_or_regexp(array)
      Regexp.new "^"+array_to_or_regexp_string(array)+"$"
    end

    def array_to_or_regexp(array)
      Regexp.new array_to_or_regexp_string(array)
    end
  end
end

class BinaryOperatorProcessor
  attr_accessor :node_class, :exact_operator_precedence, :regexp_operator_precedence, :right_operators
  def initialize(operator_precedence,node_class,right_operators)
    @right_operators_regexp= right_operators && Tools::array_to_anchored_or_regexp(right_operators)
    @node_class=node_class
    @exact_operator_precedence={}
    @regexp_operator_precedence=[]

    operator_precedence.each_with_index do |op_level,i|
      (op_level.kind_of?(Array) ? op_level : [op_level]).each do |op|
        precedence = operator_precedence.length - i
        case op
        when String, Symbol then @exact_operator_precedence[op.to_s] = precedence
        when Regexp then @regexp_operator_precedence << [op,precedence]
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
      operator_string = operator.to_s
      precedence = operator_precedence(operator_string)
      right_associative = @right_operators_regexp && operator_string[@right_operators_regexp]
      if !lowest || (right_associative ? precedence < lowest_precedence : precedence <= lowest_precedence)
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
