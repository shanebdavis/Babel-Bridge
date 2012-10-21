require File.join(File.dirname(__FILE__),"..","lib","babel_bridge")

describe BabelBridge do
  attr_accessor :parser

  def new_parser(&block)
    $parser_counter||=0
    $parser_counter+=1
    Object.const_set(klass_name="TestParser#{$parser_counter}",Class.new(BabelBridge::Parser,&block))
    @parser=Object.const_get(klass_name).new
  end

  #options
  #   :parser
  #   :failure_ok
  def test_parse(string,options={})
    parser = options[:parser] || @parser
    res = parser.parse(string)
    unless options[:failure_ok]
      puts parser.parser_failure_info :verbose => true unless res
      res.should_not == nil
    end
    res
  end

  it "the failure_index should be the furthest point reached, even if we managed to match successfully less" do
    new_parser do
      ignore_whitespace

      rule :statement, "while", :statement, "end"      
      rule :statement, "0"
      rule :statement, /[_a-zA-Z][_a-zA-Z0-9]*/
    end

    res = test_parse "while 0 foo", :failure_ok => true
    parser.failure_index.should == 8
  end

  it "parsing twice when the first didn't match all input should but the second just failed shouldn't report 'did not match entire input'" do
    new_parser do
      rule :foo, "foo"
    end

    partial_match_string = "did not match entire input"

    test_parse "foobar", :failure_ok => true
    parser.parser_failure_info[partial_match_string].should == partial_match_string
    test_parse "bar", :failure_ok => true
    parser.parser_failure_info[partial_match_string].should == nil
  end
end