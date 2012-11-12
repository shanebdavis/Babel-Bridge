=begin
Copyright 2011 Shane Brinkman-Davis
See README for licence information.
http://babel-bridge.rubyforge.org/
=end

module BabelBridge
# used for String and Regexp PatternElements
# not subclassed
class TerminalNode < Node
  attr_accessor :pattern
  def initialize(parent,match_length,pattern)
    node_init(parent)
    self.match_length=match_length
    self.pattern=pattern
    consume_trailing_whitespace if ignore_whitespace?
  end

  def consume_trailing_whitespace
    offset = self.next
    if src[offset..-1].index(whitespace_regexp)==0
      range = $~.offset(0)
      self.match_length += range[1]-range[0]
    end
  end

  def inspect(options={})
    "#{text.inspect}" unless options[:simple] && text[/^\s*$/] # if simple && node only matched white-space, return nil
  end

  def matches; [self]; end
end
end
