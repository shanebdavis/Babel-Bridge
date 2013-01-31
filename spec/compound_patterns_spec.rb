require 'spec_helper'

describe "compound pattern parsing" do
  include TestParserGenerator

  it "many + []" do
    new_parser do
      rule :foo, many(["bar","baz"])
    end

    test_parse("barbaz").matches.length.should == 2
    test_parse("barbazbarbaz").matches.length.should == 4
    test_parse "barbazbar", :should_fail_at => 9
  end

  it "many + any" do
    new_parser do
      rule :foo, many(any("foo","bar"))
    end

    test_parse "foo"
    test_parse "foofoo"
    test_parse "bar"
    test_parse "barfoo"
    test_parse "barfoofoofoobarbarbarbafoo", :should_fail_at => 21
  end

  it "any + []" do
    new_parser do
      rule :foo, any(["foo","bar"],"baz")
    end

    test_parse "foobar"
    test_parse "foo", :should_fail_at => 3
    test_parse "bar", :should_fail_at => 0
    test_parse "baz"
  end

  it "[] + any" do
    new_parser do
      rule :foo, [any("foo", "bar"), "baz"], "boo"
    end

    test_parse "foobazboo"
    test_parse "barbazboo"
    test_parse "barbaz", :should_fail_at => 6
    test_parse "fooboo", :should_fail_at => 3
  end

  it "many + [] + any" do
    new_parser do
      rule :foo, many(any(["foo",/[0-9]+/],"bar"))
    end

    test_parse "foo", :should_fail_at => 3
    test_parse "foo123"
    test_parse "bar123", :should_fail_at => 3
    test_parse "barfoo123"
    test_parse "barfoo123barbarbarfoo9foo0foo1barfoo8"
  end
end
