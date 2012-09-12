require File.join(File.dirname(__FILE__),"..","..","lib","babel_bridge")

class TuringParser < BabelBridge::Parser
  ignore_whitespace

  def store
    @store||=[]
  end

  rule :statements, many(:statement,";"), match?(";") do
    def evaluate
      ret = nil
      statement.each do |s|
        ret = s.evaluate
      end
      ret
    end
  end

  rule :statement, /if\b/, :statement, /then\b/, :statement, :else_clause?, /end\b/ do
    def evaluate
      if statement[0].evaluate
        statement[1].evaluate
      else 
        else_clause.evaluate if else_clause
      end
    end
  end
  rule :else_clause, /else\b/, :statement

  rule :statement, /while\b/, :statement, /do\b/, :statements, /end\b/ do
    def evaluate
      while statement.evaluate
        statements.evaluate
      end
    end
  end

  binary_operators_rule :statement, :operand, [[:<, :<=, :>, :>=, :==], [:+, :-], [:/, :*]] do
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
  
  rule :operand, "[", :statement, "]", "=", :statement do
    def evaluate
      parser.store[statement[0].evaluate] = statement[1].evaluate
    end
  end

  rule :operand, "[", :statement, "]" do
    def evaluate
      parser.store[statement.evaluate]
    end
  end

  rule :operand, /[-]?[0-9]+/ do
    def evaluate
      to_s.to_i
    end
  end
end

BabelBridge::Shell.new(TuringParser.new).start