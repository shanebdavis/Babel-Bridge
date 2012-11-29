=begin
Copyright 2011 Shane Brinkman-Davis
See README for licence information.
http://babel-bridge.rubyforge.org/
=end

module BabelBridge
# rule node
# subclassed automatically by parser.rule for each unique non-terminal
class NonTerminalNode < Node
  attr_accessor :last_non_empty_node

  def postwhitespace_range_without_no_postwhitespace
    if  last_non_empty_node
      last_non_empty_node.postwhitespace_range
    else
      prewhitespace_range || (0..-1)
    end
  end

  def update_match_length
    @match_length = last_non_empty_node ? last_non_empty_node.offset_after_match - offset : 0
  end

  #*****************************
  # Array interface implementation
  #*****************************
  def matches
    @matches ||= []
  end

  include Enumerable
  def length
    matches.length
  end

  def <<(node)
    @last_non_empty_node = node unless node.kind_of?(EmptyNode)
    matches<<node
    update_match_length
  end

  def [](i)
    matches[i]
  end

  def each(&block)
    matches.each(&block)
  end
end
end
