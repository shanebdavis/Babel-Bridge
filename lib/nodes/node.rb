module BabelBridge

# this is just so we can distinguish between normal arrays and arrays of matches
# - since a match can be an Array in the case of Poly-matches
class MultiMatchesArray < Array
end

# base class for all parse-tree nodes
class Node
  attr_accessor :src,:offset,:match_length,:parent,:parser

  def ignore_whitespace?
    parser.ignore_whitespace?
  end

  def to_s
    parser.ignore_whitespace? ? text.strip : text
  end

  def to_sym
    to_s.to_sym
  end

  def node_init(parent_or_parser)
    self.match_length=0
    case parent_or_parser
    when Parser then
      self.parser=parent_or_parser
      self.offset=0
      self.src=parser.src
    when Node then
      self.parent=parent_or_parser
      self.parser=parent.parser
      self.offset=parent.next
      self.src=parent.src
      raise "parent node does not have parser set" unless parser
    else
      raise "parent_or_parser(#{parent_or_parser.class}) must be a Node or a Parser"
    end
  end

  def initialize(parent)
    node_init(parent)
  end

  # after a node has been matched, the node will get this called on itself
  # It can then rewrite itself however it wishes
  def post_match
    self
  end

  # Returns a human-readable representation of the parse tree
  # options
  #   :simple => output a simplified representation of the parse tree
  def inspect(options={})
    "(TODO: def #{self.class}#inspect(options={}))"
  end

  #********************
  # info methods
  #********************
  def next; offset+match_length end       # index of first character after match
  def text; src[offset,match_length] end  # the substring in src matched

  # length returns the number of sub-nodes
  def length
    0
  end

  def parent_list
    return parent ? parent.parent_list+[parent] : []
  end

  def node_path
    "#{parent && (parent.node_path+' > ')}#{self.class}(#{offset})"
  end

  #*****************************
  # Array interface implementation
  #*****************************
  def matches # override this with function that returns array of matches to be used for Array indexing and iteration
    []
  end

  include Enumerable
  def length
    matches.length
  end

  def <<(node)
    matches<<node
  end

  def add_delimiter(node)
    delimiter_matches<<node
  end

  def [](i)
    matches[i]
  end

  def each(&block)
    matches.each(&block)
  end
end

class RootNode < Node
end
end