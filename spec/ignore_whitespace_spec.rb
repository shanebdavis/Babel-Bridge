require 'spec_helper'

describe "ignore_whitespace" do
  include TestParserGenerator

  it "ignore_whitespace should work" do
    new_parser do
      ignore_whitespace
      rule :foobar, "foo", "bar"
    end

#    test_parse "foobar"
#    test_parse "foo bar"
#    test_parse "foo  \t \r \f \n    bar"
#    test_parse " foobar"
    test_parse "foobar "
  end

  it "ignore_whitespace should work with many" do
    new_parser do
      ignore_whitespace
      rule :foobar, many("foo")
    end

    test_parse "foo"
    test_parse "foofoo"
    test_parse "foo     foo"
    test_parse "foo foo\nfoo"
  end

  it "custom delimiter should work" do
    new_parser do
      ignore_whitespace
      rule :pair, "0", "0", :delimiter => /-*/
    end

    test_parse "00"
    test_parse "0-0"
    test_parse " 0-0"
    test_parse " 0-0 "
    test_parse " 0--0 "
  end

  it "custom // delimiter should work" do
    new_parser do
      ignore_whitespace
      rule :pair, "0", "0", :delimiter => //
    end

    test_parse "00"
    test_parse " 00"
    test_parse " 00 "
    test_parse "0 0", :should_fail_at => 1
  end


  it "custom delimiter should work" do
    new_parser do
      ignore_whitespace

      rule :pair, :statement, :end_statement, :statement, :delimiter => //
      rule :end_statement, /([\t ]*[\n;])+([\t ]*)?/
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

  it "custom delimiters should work even with EmptyNodes" do
    new_parser do
      ignore_whitespace

      rule :pair, :statement, :end_statement, :statement, :delimiter => //
      rule :end_statement, /([\t ]*[\n;])+([\t ]*)?/
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

  it "custom delimiters should work with many" do
    new_parser do
      ignore_whitespace
      rule :statements, many(:statement,:end_statement), :delimiter => //
      rule :end_statement, /([\t ]*[\n;])+([\t ]*)?/
      rule :statement, "0"
    end

    test_parse "0"
    test_parse "0\n0"
    test_parse "0\n0;0"
    test_parse "0 0", :should_fail_at => 2
  end

  it "custom global delimiter should work" do
    new_parser do
      delimiter /[_\s]*/

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
      rule :two, :statement, :statement do
        def to_model
          statement.map {|a|a.to_model}
        end
      end
      rule :statement, :identifier, :parameter?, :delimiter => // do
        def to_model
          [identifier.to_sym, parameter && parameter.identifier.to_sym]
        end
      end
      rule :parameter, /[ \t]*/, :identifier, :delimiter => //
      rule :identifier, /[_a-zA-Z][_a-zA-Z0-9]*/
    end

    test_parse("fred\nbar") {|parsed|parsed.to_model.should == [[:fred,nil],[:bar,nil]]}
    test_parse("fred foo\nbar") {|parsed|parsed.to_model.should == [[:fred,:foo],[:bar,nil]]}
  end

  it "should work to have nested custom delimiters" do
    new_parser do
      ignore_whitespace
      rule :all, :call, :call do
        def to_model
          call.collect &:to_model
        end
      end
      rule :call, :identifier, :parameters?, :delimiter => // do
        def to_model
          [identifier.to_sym, parameters && parameters.to_s]
        end
      end
      rule :parameters, /[ \t]*/, many(:identifier,","), :delimiter => //
      rule :identifier, /[_a-zA-Z][_a-zA-Z0-9]*/
    end

    test_parse("fred\nbar")           {|parsed| parsed.to_model.should==[[:fred,nil],[:bar,nil]]}
    test_parse("fred foo\nbar")       {|parsed| parsed.to_model.should==[[:fred," foo"],[:bar,nil]]}
    test_parse("fred foo,bar\nbar")   {|parsed| parsed.to_model.should==[[:fred," foo,bar"],[:bar,nil]]}
  end

  it "dont.match shouldn't consume any whitespace" do
    new_parser do
      ignore_whitespace
      rule :statements, :statement, "bar"
      rule :statement, :identifier, :parameters?, :delimiter => //
      rule :parameters, / */, :identifier, :delimiter => //
      rule :identifier, dont.match("end"), /[_a-zA-Z][_a-zA-Z0-9]*/
    end

    test_parse("fred\nbar")
    #test_parse("fred foo\nbar")
  end

  it "delimiter should work" do
    new_parser do
      delimiter :custom_delimiter
      rule :foobar, "foo", "bar"
      rule :custom_delimiter, /-*/
    end

    test_parse "foobar"
    test_parse "foo-bar"
    test_parse "foo---bar"
  end

  it "should work to have many parsing with whitespace tricks" do
    new_parser do
      ignore_whitespace
      #rule :statements, many(:statement,:end_statement), :delimiter => //
      #rule :end_statement, /([\t ]*[;\n])+/
      #rule :statement, :bin_op
      binary_operators_rule :bin_op, :int, ["**", [:/, :*], [:+, "-"]], :right_operators => ["**"]
      rule :int, /\d+/
    end

=begin
NOTES: the problem is the post-parsing results method-missing methods don't work well.

If a named pattern is never matched, method-missing will fail. It should return nil.
If a named pattern may match 1 or more times, you will get back a singleton OR an array depending on the number of times.

I think the right answer is to drop method-missing entirely. Instead, when the rule is declared, create the accessor methods explicitly.

If a named pattern could match more than once, it will always return an array.

If it could match 0 times, it will work and return nil, if 0 times were indeed matched.

=end
    test_parse "3"
=begin
    test_parse "3+4"
    test_parse <<ENDCODE
      3+4
      9-2
      4
ENDCODE
=end
  end

end
