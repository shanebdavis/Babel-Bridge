# basic parser that accepts only legal JSON

require File.join(File.dirname(__FILE__),"..","..","lib","babel_bridge")

class JsonParser < BabelBridge::Parser
  ignore_whitespace

  rule :document, any(:object, :array)

  rule :array,  '[', many?(:value, ','), ']'
  rule :object, '{', many?(:pair,  ','), '}'

  rule :pair, :string, ':', :value

  rule :value, any(:object, :array, :number, :string, :true, :false, :null)

  rule :string, /"(?:[^"\\]|\\(?:["\\\/bfnrt]|u[0-9a-fA-F]{4}))*"/
  rule :number, /-?(?:0|[1-9]\d*)(?:\.\d+)?(?:[eE][+-]?\d+)?/
  rule :true,   "true"
  rule :false,  "false"
  rule :null,   "null"
end

BabelBridge::Shell.new(JsonParser.new).start
