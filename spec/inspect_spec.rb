require 'spec_helper'

describe "ManyNode#inspect" do
  include TestParserGenerator

  def basic_multi_parser
    new_parser do
      rule :foobar, many("foo", ",")
    end
  end

  def inspect_test(a,options={})
    a.inspect(options).rstrip.gsub(/[ \t]+\n/,"\n")+"\n"
  end

  it "with no options should look like this" do
    basic_multi_parser
    test_parse("foo").inspect.should == 'FoobarNode1 > "foo"'
    inspect_test(test_parse("foo,foo,foo")).should == <<ENDINSPECT
FoobarNode1 >
  + "foo"
  + "foo"
  + "foo"
ENDINSPECT
  end

  it "with :simple=>true should look like this" do
    basic_multi_parser
    test_parse("foo").inspect(:simple=>true).should == 'FoobarNode1 > "foo"'
    inspect_test(test_parse("foo,foo,foo"),:simple=>true).should == <<ENDINSPECT

  + "foo"
  + "foo"
  + "foo"
ENDINSPECT
  end

  it "with :verbose=>true should look like this" do
    basic_multi_parser
    test_parse("foo").inspect(:verbose=>true).should == 'FoobarNode1 > ["foo"]'
    inspect_test(test_parse("foo,foo,foo"),:verbose=>true).should == <<ENDINSPECT
FoobarNode1 > [
  + "foo"
  - ","
  + "foo"
  - ","
  + "foo"
]
ENDINSPECT
  end
end
