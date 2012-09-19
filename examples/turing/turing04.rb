require File.join(File.dirname(__FILE__),"..","..","lib","babel_bridge")

class TuringParser < BabelBridge::Parser

  rule :add, :int, /[-+\/*]/, :add do
    def evaluate
      int.evaluate.send matchs[1].to_s.to_sym, add.evaluate
    end
  end
  rule :add, :int
  
  rule :int, /[-]?[0-9]+/ do
    def evaluate
      to_s.to_i
    end
  end
end

BabelBridge::Shell.new(TuringParser.new).start