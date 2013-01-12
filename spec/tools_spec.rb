require 'spec_helper'

describe "Tools::" do
  include TestParserGenerator


  it "line_column" do
    BabelBridge::Tools.line_column("",           0).should == [1,1]
    BabelBridge::Tools.line_column(" ",          0).should == [1,1]
    BabelBridge::Tools.line_column("a\nbb\nccc", 0).should == [1,1]
    BabelBridge::Tools.line_column("a\nbb\nccc", 1).should == [1,2]
    BabelBridge::Tools.line_column("a\nbb\nccc", 2).should == [2,1]
    BabelBridge::Tools.line_column("a\nbb\nccc", 3).should == [2,2]
    BabelBridge::Tools.line_column("a\nbb\nccc", 4).should == [2,3]
    BabelBridge::Tools.line_column("a\nbb\nccc", 5).should == [3,1]
    BabelBridge::Tools.line_column("a\nbb\nccc", 6).should == [3,2]
    BabelBridge::Tools.line_column("a\nbb\nccc", 7).should == [3,3]
    BabelBridge::Tools.line_column("a\nbb\nccc", 8).should == [3,4]
    BabelBridge::Tools.line_column("a\nbb\nccc", 9).should == [3,4]
  end
end
