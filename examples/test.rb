require File.join(File.dirname(__FILE__),"..","lib","babel_bridge")

class TestParser < BabelBridge::Parser

  rule :expr, :bin_op do
    def evaluate
      output = bin_op.evaluate
      input = to_s
      puts "bbtest: #{output} = #{eval output}"
      puts "ruby: #{input} = #{eval input}"
    end
  end

  #rule :bin_op, :operand, "+", :operand do
  #rule :bin_op, many(:operand,"+") do
  #rule :bin_op, :operand, /([-+\/*])|(\*\*)/, :bin_op do
  #rule :bin_op, many(:operand,/([-+\/*])|(\*\*)/) do
  binary_operators_rule :bin_op, :operand, ["**", [:/, :*], [:+, "-"]], :right_operators => ["**"] do
    def evaluate 
      "(#{left.evaluate}#{operator}#{right.evaluate})"
    end
  end

  rule :operand, "(", :bin_op, ")"
 
  rule :operand, /[-]?[0-9]+/ do
    def evaluate; to_s; end
  end
end

BabelBridge::Shell.new(TestParser.new).start