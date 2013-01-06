module BabelBridge

# this is just so we can distinguish between normal arrays and arrays of matches
# - since a match can be an Array in the case of Poly-matches
class MultiMatchesArray < Array
end

# base class for all parse-tree nodes
class Node
  attr_accessor :src,:offset,:match_length,:parent,:parser,:delimiter,:many_delimiter

  def relative_class_name
    (self.class.to_s.split(parser.class.to_s+"::",2)[1]||self.class.to_s).strip
  end

  # the index of the first character after the match
  def offset_after_match
    offset + match_length
  end

  def remaining_src(sub_offset)
    src[self.next+sub_offset..-1]
  end

  def match_range
    offset..(offset+match_length-1)
  end

  # called when a ruled is matched
  def on_matched
  end

  def init_line_column
    @line, @column = Tools.line_column(src, offset)
  end

  def line
    init_line_column unless @line
    @line
  end

  def column
    init_line_column unless @column
    @column
  end

  def to_s
    text
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

  # Returns a human-readable representation of the parse tree
  # options
  #   :simple => output a simplified representation of the parse tree
  def inspect(options={})
    "(TODO: def #{self.class}#inspect(options={}))"
  end

  #********************
  # info methods
  #********************
  alias :next :offset_after_match
  def text; src[match_range] end  # the substring in src matched

  # length returns the number of sub-nodes
  def length
    0
  end

  def parent_list
    return parent ? parent.parent_list+[parent] : []
  end

  # walk down the children chain as long as there is only one child at each level
  # log and return the path
  def onlychildren_list
    if matches.length == 1
      [self] + matches[0].onlychildren_list
    else
      [self]
    end
  end

  def path_string(node_list)
    node_list.collect{|n|n.class}.join ' > '
  end

  def node_path
    path_string parent_list
  end
end

end
