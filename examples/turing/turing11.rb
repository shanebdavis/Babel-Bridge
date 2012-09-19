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

  rule :statement, "if", :statement, "then", :statements, :else_clause?, "end" do
    def evaluate
      if statement.evaluate
        statements.evaluate
      else 
        else_clause.evaluate if else_clause
      end
    end
  end
  rule :else_clause, "else", :statements

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