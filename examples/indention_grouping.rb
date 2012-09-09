require "rubygems"
require "babel_bridge"

class MyParser < BabelBridge::Parser
  def initialize
    super
    @indentions=[]
    @tab=" "*4
  end

  def rollback_indention(offset)
    @indentions.pop while @indentions.length>0 && @indentions[-1].offset>=offset
  end

  def test_indention(parent_node)
    offset=parent_node.next
    src=parent_node.src

    rollback_indention(offset)

    regex=/\A[ \t]*/
    puts "test_indention offset=#{offset}"
    if parent_node.src[offset..-1].index(regex)==0
      matched_indent_string=$~.to_s
      range=$~.offset(0)
      matched_indent_string.gsub("\t",@tab)
    puts "test_indention offset=#{offset} match=#{matched_indent_string.inspect} indentions=#{@indentions.collect{|a|a.match_length}.inspect}"
      if matched_indent_string && yield(@indentions,matched_indent_string)
        puts "match"
        @indentions<<BabelBridge::TerminalNode.new(parent_node,range[1]-range[0],regex)
        @indentions[-1]
      else
        puts "nomatch"
        nil
      end
    end
  end

  rule :file, :sub_nodes, :rest
  rule :node, :stuff, :endl, :sub_nodes?
  rule :stuff, /[a-zA-Z][a-zA-Z0-9]*/
  rule :sub_nodes, :increased_indention, many(:node,:same_indention)
  rule :endl, /[\t ]*\n/
  rule :rest, /.*/

  rule :increased_indention, {:parser=>lambda do |parent_node|
    puts "increase"
    parent_node.parser.test_indention(parent_node) do |indentions,matched_indent_string|
      indentions.length==0 || matched_indent_string.length>indentions[-1].match_length
    end
  end}

  rule :same_indention, {:parser=>lambda do |parent_node|
    puts "same"
    parent_node.parser.test_indention(parent_node) do |indentions,matched_indent_string|
      indentions.length>0 && matched_indent_string.length==indentions[-1].match_length
    end
  end}
end

parser = MyParser.new
res=parser.parse($stdin.read)
if res
  puts "success"
  puts res.inspect
else
  puts parser.parser_failure_info
end
