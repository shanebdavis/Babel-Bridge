require File.join(File.dirname(__FILE__),"..","..","lib","babel_bridge")

class TuringParser < BabelBridge::Parser
  ignore_whitespace

  rule :statement, "if", :statement, "then", :statement, :else_clause?, "end" do
    def evaluate
      if matches[1].evaluate
        matches[3].evaluate
      else 
        else_clause.evaluate if else_clause
      end
    end
  end
  rule :else_clause, "else", :statement

  binary_operators_rule :statement, :operand, [[:/, :*], [:+, :-], [:<, :<=, :>, :>=, :==]] do
    def evaluate
      case operator
      when :<, :<=, :>, :>=, :==
        (left.evaluate.send operator, right.evaluate) ? 1 : nil
      else
        left.evaluate.send operator, right.evaluate
      end
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