require 'spec_helper'

describe "many parsing" do
  include TestParserGenerator

  it "anonymous manys should work" do
    new_parser do
      rule :foo, many("bar")
    end

    test_parse("bar").matches.length.should == 1
    test_parse("barbar").matches.length.should == 2
  end

  it "named manys should work" do
    new_parser do
      rule :foo, many(:bar)
      rule :bar, "bar"
    end

    test_parse("bar").bar.class.should == BabelBridge::MultiMatchesArray
    test_parse("barbar").bar.class.should == BabelBridge::MultiMatchesArray
  end

  it "parse that matches nothing on a many? on the first character should still report valid parser_failure_info" do
    new_parser do
      rule :foo, many?("foo")
    end

    res = parser.parse "bar"
    parser.parser_failure_info(:verbose => true).class.should == String
  end

  it "many with .as should work" do
    new_parser do
      rule :foo, many("foo").as(:boo)
    end

    test_parse("foo").boo.join(',').should == "foo"
    test_parse("foofoo").boo.join(',').should == "foo,foo"
    test_parse("foofoofoo").boo.join(',').should == "foo,foo,foo"
  end

  it "many with delimiter" do
    new_parser do
      rule :foo, many("foo",";").as(:foo)
    end
    test_parse("foo").foo.collect {|f| f.text}.should == %w{foo}
    test_parse("foo;foo").foo.collect {|f| f.text}.should == %w{foo foo}
  end

  it "test_poly_optional_delimiter" do
    parser=new_parser do
      rule :foo, many(";",match?(/ +/))
    end
    test_parse ";"
    test_parse ";;"
    test_parse ";    ;   ;"
  end
end
