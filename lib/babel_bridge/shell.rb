require "readline"

module BabelBridge
class Shell
  attr_accessor :parser
  def initialize(parser)
    @parser = parser
  end

  def pretty_print_parse_tree(parse_tree_node)
    puts "\nParse tree:\n  #{parse_tree_node.inspect.gsub("\n","\n  ")}\n\n"
  end

  # Providing a block overrides all evaluate behavor and simply:  yield parse_tree_node, self
  # elsif parse_tree_node responds to "evaluate":                 puts_result parse_tree_node.evaluate
  # else                                                          pretty-print the parse-tree
  # rescue and pretty-print errors
  def evaluate(parse_tree_node, &block)
    if block
      yield parse_tree_node, self
    elsif parse_tree_node.respond_to? :evaluate
      puts_result parse_tree_node.evaluate
    else
      pretty_print_parse_tree parse_tree_node
    end
  rescue Exception => e
    errputs "Error evaluating parse tree: #{e}\n" + ["Backtrace:",e.backtrace].flatten.join("\n  ")
    pretty_print_parse_tree parse_tree_node
  end

  def puts(str)
    @stdout.puts str
  end

  def puts_result(str)
    @stdout.puts " => "+str.inspect
  end

  def errputs(str)
    @stderr.puts str
  end

  # Each line of input is parsed.
  # If parser fails, output explaination of why.
  # If parser succeeds, evaluate parse_tree_node, &block
  def start(options={},&block)
    @stdout = options[:stdout] || $stdout
    @stderr = options[:stdout] || @stdout
    @stdin = options[:stdin] || $stdin
    while line = @stdin == $stdin ? Readline.readline("> ", true) : @stdin.gets      
      line.strip!
      next if line.length==0
      parse_tree_node = parser.parse line
      if parse_tree_node
        evaluate parse_tree_node, &block
      else
        errputs parser.parser_failure_info :verbose => true
      end
    end
  end
end
end