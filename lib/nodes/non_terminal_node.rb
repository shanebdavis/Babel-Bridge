=begin
Copyright 2011 Shane Brinkman-Davis
See README for licence information.
http://babel-bridge.rubyforge.org/
=end

module BabelBridge
# rule node
# subclassed automatically by parser.rule for each unique non-terminal
class NonTerminalNode < Node

  def update_match_length
    @match_length = last_match ? last_match.offset_after_match - offset : 0
  end

  #*****************************
  # Array interface implementation
  #*****************************
  def matches
    @matches ||= []
  end

  def last_match
    matches[-1]
  end

  include Enumerable
  def length
    matches.length
  end

  def add_match(node)
    return if !node || node.kind_of?(EmptyNode) || node == self
    node.tap do
      matches << node
      update_match_length
    end
  end

  def [](i)
    matches[i]
  end

  def each(&block)
    matches.each(&block)
  end
end
end
