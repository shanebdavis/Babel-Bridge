=begin
Copyright 2011 Shane Brinkman-Davis
See README for licence information.
http://babel-bridge.rubyforge.org/
=end

module BabelBridge

# used when a PatternElement matchs the empty string
# Example: when the PatternElement is optional and doesn't match
# not subclassed
class EmptyNode < Node
  def inspect(options={})
    "EmptyNode" unless options[:simple]
  end

  def matches; [self]; end

end

class RollbackWhitespaceNode < Node
  def inspect(options={})
    "RollbackWhitespace" unless options[:simple]
  end

  def matches; [self]; end

  def initialize(parent)
    super
    self.match_length = 0
    self.offset = parent.postwhitespace_range.first
  end

  def postwhitespace_range
    @postwhitespace_range ||= offset_after_match .. offset_after_match-1
  end

end
end
