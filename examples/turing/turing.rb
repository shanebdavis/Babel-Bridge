require File.join(File.dirname(__FILE__),"..","..","lib","babel_bridge")

class TuringParser < BabelBridge::Parser

  rule :expr, :add

  rule( :add, :sub, "+", :add)    {def evaluate; sub.evaluate + add.evaluate; end}
  rule( :sub, :div, "-", :sub)    {def evaluate; div.evaluate - sub.evaluate; end}
  rule( :div, :mul, "/", :div)    {def evaluate; mul.evaluate / div.evaluate; end}
  rule( :mul, :prn, "*", :mul)    {def evaluate; prn.evaluate * mul.evaluate; end}

=begin
# sketch of how to automatically match a string of binary operators based on precedence 
  binary_operators_rule :bin_op, %w{+ - / *}, :prn do
    def evaluate
      case operator
      when "+" do left.evalute + right.evaluate
      when "-" do left.evalute + right.evaluate
      when "/" do left.evalute + right.evaluate
      when "*" do left.evalute + right.evaluate
      end
    end
  end
=end  
  
  rule :add, :sub
  rule :sub, :div
  rule :div, :mul
  rule :mul, :prn

  rule :prn, "(", :expr, ")"
  rule :prn, :int

  rule :int, /[-]?[0-9]+/ do
    def evaluate; to_s.to_i; end
  end
end

BabelBridge::Shell.new(TuringParser.new).start