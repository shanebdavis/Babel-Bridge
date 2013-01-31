require File.join(File.dirname(__FILE__),"..","..","lib","babel_bridge")

class JsonParser < BabelBridge::Parser
  rule :document, :object
  rule :document, :array

  rule :array, '[', many?(:value, ','), ']'

  rule :object, '{', many?(:pair, ','), '}'

  rule :pair, :string, ':', :value

  rule :value, :object
  rule :value, :array
  rule :value, :number
  rule :value, :string
  rule :value, :true
  rule :value, :false
  rule :value, :null

  rule :string, /"(?:[^"\\]|\\(?:["\\\/bfnrt]|u[0-9a-fA-F]{4}))*"/
  rule :number, /-?(?:0|[1-9]\d*)(?:\.\d+)?(?:[eE][+-]?\d+)?/
  rule :true, "true"
  rule :false, "false"
  rule :null, "null"
end

BabelBridge::Shell.new(JsonParser.new).start
