module BabelBridge
class Shell
  attr_accessor :parser
  def initialize(parser)
    @parser = parser
  end

  # if block is provided, successful parsers are yield to block
  # Otherwise, succuessful parsers are sent the "eval" method
  def start(options={},&block)
    stdout = options[:stdout] || $stdout
    stderr = options[:stdout] || stdout
    stdin = options[:stdin] || $stdin
    while true
      stdout.print "> "
      line = stdin.gets
      ret = parser.parse line.strip
      if ret
        if block
          yield ret
        else
          stdout.puts " => #{ret.evaluate}"
        end
      else
        stderr.puts parser.parser_failure_info
      end
    end
  end
end
end