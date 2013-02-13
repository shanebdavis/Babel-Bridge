require 'spec_helper'

describe BabelBridge do
  include TestParserGenerator

  it "the failure_index should be the furthest point reached, even if we managed to successfully match less" do
    new_parser do
      ignore_whitespace

      rule :statement, "while", :statement, "end"
      rule :statement, "0"
      rule :statement, /[_a-zA-Z][_a-zA-Z0-9]*/
    end

    res = test_parse "while 0 foo", :should_fail_at => 8
  end

  it "parsing twice when the first didn't match all input should, but the second just failed, shouldn't report 'did not match entire input'" do
    new_parser do
      rule :foo, "foo"
    end

    partial_match_string = "did not match entire input"

    test_parse "foobar", :failure_ok => true
    parser.parser_failure_info[partial_match_string].should == partial_match_string
    test_parse "bar", :failure_ok => true
    parser.parser_failure_info[partial_match_string].should == nil
  end

  it "should work to have many-many parsing" do
    new_parser do
      rule :top, many(:bottom,";")
      rule :bottom, many("0",",")
    end

    test_parse "0"
    test_parse "0;0"
    test_parse "0,0"
    test_parse "0,0;0"
    test_parse "0;0,0"
    test_parse "0,0,0;0;0,0,0"
  end

  it "if a name can be optionally matched more than one time, it should always be an array of matchs" do
    new_parser do
      rule :foo, :bar, :bar?
      rule :bar, "bar"
    end

    test_parse("bar").bar.class.should == BabelBridge::MultiMatchesArray
    test_parse("barbar").bar.class.should == BabelBridge::MultiMatchesArray
  end

  it "if a name can be optionally matched more than one time, it should always be an array of matchs" do
    new_parser do
      rule :file, :space, :constant
      rule :space, /\s*/
      rule :constant, /[A-Z][0-9_a-zA-Z]*/
    end

    p = test_parse("This")

    p.constant.match_length.should == 4
    p.space.match_length.should == 0

    p.constant.match_range.should == (0..3)
    p.space.match_range.should == (0..-1)

    p.constant.to_s.should == "This"
    p.space.to_s.should == ""
  end

end
