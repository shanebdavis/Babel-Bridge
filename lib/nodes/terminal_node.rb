=begin
Copyright 2011 Shane Brinkman-Davis
See README for licence information.
http://babel-bridge.rubyforge.org/
=end

module BabelBridge
# used for String and Regexp PatternElements
# not subclassed
class TerminalNode < Node
  attr_accessor :pattern, :trailing_whitespace_offset
  def initialize(parent,range,pattern)
    node_init(parent)
    self.offset = range.min
    self.match_length = range.max-range.min
    self.pattern = pattern
  end

  def inspect(options={})
    "#{text.inspect}" unless options[:simple] && text[/^\s*$/] # if simple && node only matched white-space, return nil
  end

  def matches; [self]; end

end
end
