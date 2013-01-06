require 'spec_helper'

describe "basic parsing" do
  include TestParserGenerator

  it "offset, matchs, text, and length" do
    new_parser do
      rule :foo, "foo", match?("bar")
    end

    test_parse("foo").offset.should == 0
    test_parse("foobar").matches[1].offset.should == 3
    test_parse("foo").length.should == 1
    test_parse("foobar").length.should == 2
    test_parse("foo").text.should == "foo"
    test_parse("foobar").to_s.should == "foobar"
  end

  it "test custom node methods" do
    new_parser do
      rule :number, /[0-9]+/ do
        def number
          text.to_i
        end
      end
    end

    test_parse("123").number.should == 123
  end

  def test_adder
    new_parser do
      rule :adder, :number, "+", :number do
        def answer;
          number[0].number + number[1].number
        end
      end
      rule :number, /[0-9]+/ do
        def number; text.to_i end
      end
    end


    test_parser("123+654").answer.should == 777
  end

  def test_adder_multiplier
    new_parser do

      rule :adder, :multiplier, "+", :adder do
        def value
          multiplier.value + adder.value
        end
      end

      rule :adder, :multiplier do
        def value
          multiplier.value
        end
      end

      rule :multiplier, :number, "*", :multiplier do
        def value
          number.value * multiplier.value
        end
      end

      rule :multiplier, :number do
        def value
          number.value
        end
      end

      rule :number, /[0-9]+/ do
        def value; text.to_i end
      end

    end

    test_parse("123").value.should == 123
    test_parse("123*3").value.should == 123*3
    test_parse("123*3+1").value.should == 123*3+1
    test_parse("123+3*2").value.should == 123+3*2
    test_parse("123+654").value.should == 123+654
    test_parse("20*4+1+100*2").value.should == 20*4+1+100*2
  end


  it "test_indexed_match_reference_with_optional" do
    new_parser do
      rule :foo, :bar, :boo?, :bar do
        def outter
          bar[0].text + bar[1].text
        end
      end
      rule :bar, /[0-9]+,?/
      rule :boo, /[A-Z]+,?/
    end

    test_parse("1,2").outter.should == "1,2"
    test_parse("1,A,3").outter.should == "1,3"
  end
end
