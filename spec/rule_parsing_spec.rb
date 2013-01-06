require 'spec_helper'

describe "more complex rule structure parsing" do
  include TestParserGenerator

  it "sub-rules should work" do
    new_parser do
      rule :foo, "foo", :bar
      rule :bar, "bar"
    end

    test_parse "foo", :should_fail_at => 3
    test_parse "foobar"
  end

  it "optional rule" do
    new_parser do
      rule :foo, "foo", :bar?
      rule :bar, "bar"
    end

    test_parse "foo"
    test_parse "foobar"
  end

  it "not-match rule" do
    new_parser do
      rule :foo, :boo!, /[a-zA-Z]+/
      rule :boo, "boo"
    end

    test_parse "boo", :should_fail_at => 0
    test_parse "foo"
    test_parse "boO"
  end

  it "rule variants should work" do
    v1=nil
    v2=nil
    new_parser do
      v1=rule :foo, "foo"
      v2=rule :foo, "bar"
    end

    test_parse("foo").class.should == v1
    test_parse("bar").class.should == v2
    test_parse "baz", :should_fail_at => 0
  end

  it "test right-recursive" do
    new_parser do
      rule :foo, "foo", :foo?
    end

    test_parse "foo"
    test_parse "foofoo"
    test_parse "foofoofoo"
  end


end
