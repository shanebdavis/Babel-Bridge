=begin
Copyright 2011 Shane Brinkman-Davis
See README for licence information.
http://babel-bridge.rubyforge.org/
=end

module BabelBridge
# used for String and Regexp PatternElements
# not subclassed
class TerminalNode < Node
  attr_accessor :pattern, :postwhitespace_offset
  def initialize(parent,range,pattern)
    node_init(parent)
    self.offset = range.min
    self.match_length = range.max-range.min
    self.pattern = pattern
    puts match_length:match_length, offset:offset, match_range:match_range, range:range
  end

  def inspect(options={})
    "#{text.inspect}" unless !options[:verbose] && text[/^\s*$/] # if only show whitespace matches if verbose
  end

  def matches; []; end
#  def matches; [self]; end

end
end
