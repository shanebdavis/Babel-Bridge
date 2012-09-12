require File.join(File.dirname(__FILE__),"..","..","lib","babel_bridge")

class TuringParser < BabelBridge::Parser
  def store
    @store||=[]
  end

  rule :statement, :if_statement
  rule :statement, :store_statement
  rule :statement, :expr
  
  rule :store_statement, "[", :statement, "]=", :statement do
    def evaluate
      parser.store[matches[1].evaluate] = matches[3].evaluate
    end
  end
  
  rule :if_statement, /if\s+/, :statement, /then\s+/, :statement, /else\s+/, :statement, /end\b/ do
    def evaluate
      statement[0].evaluate ? statement[1].evaluate : statement[2].evaluate
    end
  end

  rule :expr, :bin_op
  rule :expr, :fetch_expr

  rule :fetch_expr, "[", :statement, "]" do
    def evaluate
      parser.store[statement.evaluate]
    end
  end

  binary_operators_rule :bin_op, :paren_expr, [[:<, :<=, :>, :>=, :==], [:+, :-], [:/, :*]] do
    def evaluate
      case operator
      when :<, :<=, :>, :>=, :==
        (left.evaluate.send operator, right.evaluate) ? 1 : nil
      else
        left.evaluate.send operator, right.evaluate
      end
    end
  end

  rule :paren_expr, "(", :statement, ")"
  rule :paren_expr, :int

  rule :int, /[-]?[0-9]+/ do
    def evaluate; to_s.to_i; end
  end
end

BabelBridge::Shell.new(TuringParser.new).start