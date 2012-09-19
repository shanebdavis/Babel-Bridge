require "readline"

module BabelBridge
class Shell
  attr_accessor :parser
  def initialize(parser)
    @parser = parser
  end

  def evaluate(parse_tree_node)
    if parse_tree_node.respond_to? :evaluate
      " => "+parse_tree_node.evaluate.inspect
    else
      "\nParse tree:\n  "+
      parse_tree_node.inspect.gsub("\n","\n  ")+"\n\n"
    end
  rescue Exception => e
    @stderr.puts "Error evaluating parse tree: #{e}\n  "+e.backtrace.join("\n  ")+"\nParse Tree:\n"+parse_tree_node.inspect
  end

  # if block is provided, successful parsers are yield to block
  # Otherwise, succuessful parsers are sent the "eval" method
  def start(options={},&block)
    @stdout = options[:stdout] || $stdout
    @stderr = options[:stdout] || @stdout
    @stdin = options[:stdin] || $stdin
    while line = @stdin == $stdin ? Readline.readline("> ", true) : @stdin.gets      
      line.strip!
      next if line.length==0
      ret = parser.parse line
      if ret
        if block
          yield ret
        else
          @stdout.puts evaluate(ret)
        end
      else
        @stderr.puts parser.parser_failure_info :verbose => true
      end
    end
  end
end
end