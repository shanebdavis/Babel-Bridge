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
  end

  def inspect(options={})
    "#{text.inspect}" unless !options[:verbose] && text[/^\s*$/] # if only show whitespace matches if verbose
  end

  def matches; [self]; end

end
end
