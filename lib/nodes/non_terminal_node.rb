=begin
Copyright 2011 Shane Brinkman-Davis
See README for licence information.
http://babel-bridge.rubyforge.org/
=end

module BabelBridge
# rule node
# subclassed automatically by parser.rule for each unique non-terminal
class NonTerminalNode < Node

  def postwhitespace_range
    if matches.length == 0
      prewhitespace_range || (0..-1)
    else
      matches[-1].postwhitespace_range
    end
  end

  def update_match_length
    m = matches[-1]
    @match_length = m ? m.offset_after_match - offset : 0
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
