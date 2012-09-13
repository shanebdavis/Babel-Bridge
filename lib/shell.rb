require "readline"

module BabelBridge
class Shell
  attr_accessor :parser
  def initialize(parser)
    @parser = parser
  end

  def evaluate(parse_tree_node)
    if parse_tree_node.respond_to? :evaluate
      parse_tree_node.evaluate
    else
      parse_tree_node
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
      ret = parser.parse line.strip
      if ret
        if block
          yield ret
        else
          @stdout.puts " => #{evaluate(ret).inspect}"
        end
      else
        @stderr.puts parser.parser_failure_info
      end
    end
  end
end
end