require File.join(File.dirname(__FILE__),"..","..","lib","babel_bridge")

class TuringParser < BabelBridge::Parser

  binary_operators_rule :statement, :operand, [[:/, :*], [:+, :-]] do
    def evaluate
      left.evaluate.send operator, right.evaluate
    end
  end

  rule :operand, "(", :statement, ")"
  
  rule :operand, /[-]?[0-9]+/ do
    def evaluate
      to_s.to_i
    end
  end
end

BabelBridge::Shell.new(TuringParser.new).start