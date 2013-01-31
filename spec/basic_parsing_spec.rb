require 'spec_helper'

describe "basic parsing" do
  include TestParserGenerator

  it "string literal should work" do
    new_parser do
      rule :foo, "foo"
    end

    test_parse "foo"
    test_parse("foo").offset.should == 0
    test_parse("foo").text.length.should == 3
  end

  it ".as option should work" do
    new_parser do
      rule :foo, match("foo").as(:boo)
    end

    test_parse "foo"
    test_parse("foo").boo.text.should == "foo"
  end

  it "regexp should work" do
    new_parser do
      rule :foo, /[0-9]+/
    end

    %w{ 0 1 10 123 1001 }.each do |numstr|
      test_parse numstr
    end
  end

  # bb uses some regexp optimizations which could fail if not matched @ the first character of the source
  it "regexp should work even when it isn't the first match" do
    new_parser do
      rule :foo, /[0-9]+/
      rule :foo, "hi", /[0-9]+/
    end

    test_parse "123"
    test_parse "hi123"
  end

  it "test optional" do
    new_parser do
      rule :foo, "foo", :bar?
      rule :bar, "bar"
    end

    test_parse "foo"
    test_parse "foobar"
  end

  it "test could" do
    new_parser do
      rule :foo, could.match(/[a-z]/), /[a-zA-Z]+/
    end
    test_parse "FOO", :should_fail_at => 0
    test_parse "fOO"
    test_parse "foo"
  end

  it "test optional in the middle" do
    new_parser do
      rule :foo, "foo", match?("bar"), "foo"
    end

    test_parse "foofoo"
    test_parse "foobarfoo"
  end

  # this seems a little strange, but it is correct behavior for a Parsing-Expression-Grammar parser
  it "test_greedy_optional_middle" do
    new_parser do
      rule :foo, "foo", match?("foo"), "foo"
    end

    test_parse "foofoo", :should_fail_at => 6
    test_parse "foofoofoo"
  end

  it "! (not-match) should work" do
    new_parser do
      rule :foo, match!("boo"), /[a-zA-Z]+/
    end

    test_parse "boo", :should_fail_at => 0
    test_parse "foo"
    test_parse "boO"
  end

  it "any() pattern should work" do
    new_parser do
      rule :foo, any("foo","bar")
    end

    test_parse "bar"
    test_parse "foo"
    test_parse "boo", :should_fail_at => 0
  end

  it "any!() should work" do
    new_parser do
      rule :foo, any!("foo","bar"), /[a-z]+/
    end

    test_parse "bar", :should_fail_at => 0
    test_parse "foo", :should_fail_at => 0
    test_parse "boo"
  end

  it "any?() should work" do
    new_parser do
      rule :foo, any?("foo","bar"), "baz"
    end

    test_parse "barbaz"
    test_parse "foobaz"
    test_parse "baz"
    test_parse "foo", :should_fail_at => 3
  end

  it "[] (match in order) pattern should work" do
    new_parser do
      rule :foo, ["foo", "bar"], "baz"
      rule :foo, "foo", "boo"
    end

    test_parse "foobarbaz"
    test_parse "foo", :should_fail_at => 3
    test_parse "foobar", :should_fail_at => 6
    test_parse "fooboo"
  end

end
