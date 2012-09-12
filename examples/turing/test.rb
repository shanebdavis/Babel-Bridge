require File.join(File.dirname(__FILE__),"..","..","lib","babel_bridge")

class TestParser < BabelBridge::Parser

  rule :expr, :bin_op do
    def evaluate
      output = bin_op.evaluate
      input = to_s
      puts "bbtest: #{output} = #{eval output}"
      puts "ruby: #{input} = #{eval input}"
    end
  end

  #rule :bin_op, many(:int,/[-+\/*]/) do
  binary_operators_rule :bin_op, :int, [%w{+ -},[:/, :*]] do
    def evaluate  
      "(#{left.evaluate}#{operator}#{right.evaluate})"
    end
  end
 
  rule :int, /[-]?[0-9]+/ do
    def evaluate; to_s; end
  end
end

BabelBridge::Shell.new(TestParser.new).start