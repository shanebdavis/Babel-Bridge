require 'spec_helper'

describe "Tools::" do
  include TestParserGenerator


  it "line_col" do
    "".           line_col(0).should == [1,1]
    " ".          line_col(0).should == [1,1]
    "a\nbb\nccc". line_col(0).should == [1,1]
    "a\nbb\nccc". line_col(1).should == [1,2]
    "a\nbb\nccc". line_col(2).should == [2,1]
    "a\nbb\nccc". line_col(3).should == [2,2]
    "a\nbb\nccc". line_col(4).should == [2,3]
    "a\nbb\nccc". line_col(5).should == [3,1]
    "a\nbb\nccc". line_col(6).should == [3,2]
    "a\nbb\nccc". line_col(7).should == [3,3]
    "a\nbb\nccc". line_col(8).should == [3,4]
    "a\nbb\nccc". line_col(9).should == [3,4]
  end
end
