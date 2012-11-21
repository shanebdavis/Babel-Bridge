=begin
Copyright 2011 Shane Brinkman-Davis
See README for licence information.
http://babel-bridge.rubyforge.org/
=end

module BabelBridge
# rule node
# subclassed automatically by parser.rule for each unique non-terminal
class NonTerminalNode < Node

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
    matches<<node
  end

  def [](i)
    matches[i]
  end

  def each(&block)
    matches.each(&block)
  end
end
end
