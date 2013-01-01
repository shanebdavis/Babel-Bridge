require 'spec_helper'

describe BabelBridge do
  include TestParserGenerator

  it "parse that matches nothing on a many? on the first character should still report valid parser_failure_info" do
    new_parser do
      rule :foobar, many?("foo")
    end

    res = parser.parse "bar"
    parser.parser_failure_info(:verbose => true).class.should == String
  end

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

  it "should work to have many parsing with whitespace tricks" do
    new_parser do
      ignore_whitespace
      rule :statements, many(:statement,:end_statement)
      rule :end_statement, rewind_whitespace, /([\t ]*[;\n])+/
      rule :statement, :bin_op
      binary_operators_rule :bin_op, :int, ["**", [:/, :*], [:+, "-"]], :right_operators => ["**"]
      rule :int, /\d+/
    end

    test_parse "0"
    test_parse <<ENDCODE
      3+4
      9-2
      4
ENDCODE
  end

end
