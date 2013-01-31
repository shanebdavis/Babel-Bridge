# basic parser that accepts only legal JSON
# parse-tree-nodes support "#evaluate" which returns the ruby-equivalent data-structure
require File.join(File.dirname(__FILE__),"..","..","lib","babel_bridge")

class JsonParser < BabelBridge::Parser
  ignore_whitespace

  rule :document, any(:object, :array)

  rule :array, '[', many?(:value, ','), ']' do
    def evaluate; value ? value.collect {|v| v.evaluate} : []; end
  end

  rule :object, '{', many?(:pair,  ','), '}' do
    def evaluate
      h = {}
      pair.each do |p|
        h[eval(p.string.to_s)] = p.value.evaluate
      end
      h
    end
  end

  rule :pair, :string, ':', :value

  rule :value, any(:object, :array, :ruby_compatible_literal, :null)

  rule :ruby_compatible_literal, any(:number, :string, :true, :false) do
    def evaluate; eval(to_s); end
  end

  rule :string, /"(?:[^"\\]|\\(?:["\\\/bfnrt]|u[0-9a-fA-F]{4}))*"/
  rule :number, /-?(?:0|[1-9]\d*)(?:\.\d+)?(?:[eE][+-]?\d+)?/
  rule :true,   "true"
  rule :false,  "false"
  rule :null,   "null" do
    def evaluate; nil end
  end
end

BabelBridge::Shell.new(JsonParser.new).start
