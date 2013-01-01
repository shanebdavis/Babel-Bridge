require 'spec_helper'

describe "ignore_whitespace" do
  include TestParserGenerator
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

  it "include_whitespace should work" do
    new_parser do
      ignore_whitespace

      rule :pair, :statement, :end_statement, :statement
      rule :end_statement, rewind_whitespace, /([\t ]*[\n;])+/
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
      rule :end_statement, rewind_whitespace, /([\t ]*[\n;])+/
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
      rule :end_statement, rewind_whitespace, /([\t ]*[;\n])+/
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


  it "should work to rewind_whitespace, :rule" do
    new_parser do
      ignore_whitespace
      rule :all, :identifier, :parameter?, :identifier do
        def to_model
          [[identifier[0].to_sym, parameter && parameter.to_sym], identifier[1].to_sym]
        end
      end
      rule :parameter, rewind_whitespace, /[ \t]*/, rewind_whitespace, :identifier
      rule :identifier, /[_a-zA-Z][_a-zA-Z0-9]*/
    end

    test_parse("fred\nbar") {|parsed|parsed.to_model.should == [[:fred,nil],:bar]}
    test_parse("fred foo\nbar") {|parsed|parsed.to_model.should == [[:fred,:foo],:bar]}
  end

  it "should work to rewind_whitespace, many" do
    new_parser do
      ignore_whitespace
      rule :all, :identifier, :parameters?, :identifier do
        def to_model
          [[identifier[0].to_sym, parameters && parameters.to_s], identifier[1].to_sym]
        end
      end
      rule :parameters, rewind_whitespace, /[ \t]*/, rewind_whitespace, many(:identifier,",")
      rule :identifier, /[_a-zA-Z][_a-zA-Z0-9]*/
    end

    test_parse("fred\nbar")           {|parsed| parsed.to_model.should==[[:fred,nil],:bar]}
    test_parse("fred foo\nbar")       {|parsed| parsed.to_model.should==[[:fred,"foo"],:bar]}
    test_parse("fred foo, bar\nbar")  {|parsed| parsed.to_model.should==[[:fred,"foo, bar"],:bar]}
  end

  it "dont.match shouldn't consume any whitespace" do
    new_parser do
      ignore_whitespace
      rule :statements, :statement, "bar"
      rule :statement, :identifier, :parameters?
      rule :parameters, rewind_whitespace, / */, rewind_whitespace, :identifier
      rule :identifier, dont.match("end"), /[_a-zA-Z][_a-zA-Z0-9]*/
    end

    test_parse("fred\nbar")
    test_parse("fred foo\nbar")
  end

end
