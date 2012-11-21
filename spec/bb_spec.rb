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
    if options[:should_fail_at]
      res.should == nil
      parser.failure_index.should == options[:should_fail_at]
    elsif !options[:failure_ok]
      puts parser.parser_failure_info :verbose => true unless res
      res.should_not == nil
    end
    res
  end

  it "ignore_whitespace should work" do
    new_parser do
      ignore_whitespace
      rule :foobar, "foo", "bar"
    end

    test_parse "foobar"
    test_parse "foo bar"
    test_parse "foo  \t \r \f \n    bar"
    test_parse " foobar"
    test_parse "foobar "
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

  it "include_whitespace should work" do
    new_parser do
      ignore_whitespace

      rule :pair, :statement, :end_statement, :statement
      rule :end_statement, include_whitespace(/([\t ]*[\n;])+/)
      rule :statement, "0"
    end

    test_parse "0;0"
    test_parse "0\n0"
    test_parse "0   ;   0"
    test_parse "0   ; ;  0"
    test_parse "0   \n   0"
    test_parse "0   \n \n  0"
    test_parse "0   \n ;  \n  0"
    test_parse "0  ;  \n  ;0"
    test_parse "0      0", :should_fail_at => 1
  end

  it "include_whitespace should work even with EmptyNodes" do
    new_parser do
      ignore_whitespace

      rule :pair, :statement, :end_statement, :statement
      rule :end_statement, include_whitespace(/([\t ]*[\n;])+/)
      rule :statement, "0", :one?, :one?, :one?
      rule :one, "1"
    end

    test_parse "0;0"
    test_parse "01;0"
    test_parse "0\n0"
    test_parse "01\n0"
    test_parse "011\n0"
    test_parse "0111\n0"
  end

  it "include_whitespace should work with many" do
    new_parser do
      ignore_whitespace
      rule :statements, many(:statement,:end_statement)
      rule :end_statement, include_whitespace(/([\t ]*[;\n])+/)
      rule :statement, "0"
    end

    test_parse "0"
    test_parse "0\n0"
  end

  it "custom ignore_whitespace should work" do
    new_parser do
      ignore_whitespace /[_\s]*/

      rule :foobar, "foo", "bar"
    end

    test_parse "foobar"
    test_parse "foo_bar"
    test_parse "foo_ bar"
    test_parse "foo _ bar"
    test_parse "foo bar"
    test_parse "foo-bar", :should_fail_at => 3
  end

end
