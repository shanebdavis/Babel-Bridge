require 'spec_helper'

describe "advanced parsing" do
  include TestParserGenerator

  it "test_custom_parser" do
    new_parser do
      rule :foo, (custom_parser do |parent_node|
        offset=parent_node.next
        src=parent_node.src

        # Note, the \A anchors the search at the beginning of the string
        if src[offset..-1].index(/\A[A-Z]+/)==0
          endpattern=$~.to_s
          if i=src.index(endpattern,offset+endpattern.length)
            range = offset..(i+endpattern.length)
            BabelBridge::TerminalNode.new(parent_node,range,"endpattern")
          end
        end
      end)
    end

    test_parse("END this is in the middle END")
    test_parse("FROG this is in the middle FROG")
    test_parse("END this is in END the middle END",:partial_match => true).text.should == "END this is in END"
    test_parse "END this is in the middle EN", :should_fail_at => 0
    test_parse "    END this is in the middle END", :should_fail_at => 0
  end

  it "test_binary_operator_rule" do
    new_parser do
      binary_operators_rule :bin_op, :int, ["**", [:/, :*], [:+, "-"]], :right_operators => ["**"] do
        def evaluate
          "(#{left.evaluate}#{operator}#{right.evaluate})"
        end
      end

      rule :int, /[-]?[0-9]+/ do
        def evaluate; to_s; end
      end
    end
    test_parse("1+2").evaluate          .should == "(1+2)"
    test_parse("1+2+3").evaluate        .should == "((1+2)+3)"
    test_parse("1+2*3").evaluate        .should == "(1+(2*3))"
    test_parse("1*2+3").evaluate        .should == "((1*2)+3)"
    test_parse("5**6").evaluate         .should == "(5**6)"
    test_parse("1-2+3*4/5**6").evaluate .should == "((1-2)+((3*4)/(5**6)))"
    test_parse("5**6**7").evaluate      .should == "(5**(6**7))"
  end
end
