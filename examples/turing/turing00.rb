require File.join(File.dirname(__FILE__),"..","..","lib","babel_bridge")

class TuringParser < BabelBridge::Parser
  
end

BabelBridge::Shell.new(TuringParser.new).start