require File.expand_path(File.join(File.dirname(__FILE__),"..","lib","babel_bridge"))
require File.expand_path(File.join(File.dirname(__FILE__),"test_helper"))

class BBTests < TestHelper

  def new_module
   @module_counter||=0
   @module_counter+=1
   "TestModule#{@module_counter}"
  end

  def new_parser(&block)
    @parser_counter||=0
    @parser_counter+=1
    Object.const_set(klass_name="TestParser#{@parser_counter}",Class.new(BabelBridge::Parser,&block))
    Object.const_get(klass_name).new
  end

  def test_foobar
    parser=new_parser do #Class.new BabelBridge::Parser do
      rule :foo, "foo", :bar
      rule :bar, "bar"
    end

    assert_nil parser.parse("foo")
    assert parser.parse("foobar")
  end

  def test_as
    parser=new_parser do
      rule :foo, match("foo").as(:boo)
    end

    assert parser.parse("foo")
    assert_equal "foo", parser.parse("foo").boo.text
  end

  def test_many_as
    parser=new_parser do
      rule :foo, many("foo").as(:boo)
    end

    assert parser.parse("foo")
    assert parser.parse("foofoo")
    assert_equal "foofoo", parser.parse("foofoo").boo.text
  end

  def test_negative
    parser=new_parser do
      rule :foo, match!("boo"), /[a-zA-Z]+/
    end

    assert_nil parser.parse("boo")
    assert parser.parse("foo")
    assert parser.parse("boO")
    assert parser.parse("abc")
  end

  def test_foo
    parser=new_parser do
      rule :foo, ["foo"]
    end

    assert p=parser.parse("foo")
    assert_equal 0,p.offset
    assert_equal 3,p.match_length
  end

  def test_regex
    parser=new_parser do
      rule :foo, /[0-9]+/
    end

    %w{ 0 1 10 123 1001 }.each do |numstr|
      assert_equal numstr,parser.parse(numstr).text
    end
  end

  def test_regex_offset
    parser=new_parser do
      rule :foo, /[0-9]+/
      rule :foo, "hi", /[0-9]+/
    end

    assert_equal 1,parser.parse("123").matches.length
    assert_equal 2,parser.parse("hi123").matches.length
  end

  def test_optional
    parser=new_parser do
      rule :foo, ["foo", :bar?]
      rule :bar, ["bar"]
    end

    assert parser.parse("foo")
    assert parser.parse("foobar")
  end

  def test_could
    parser=new_parser do
      rule :foo, could.match(/[a-z]/), /[a-zA-Z]+/
    end
    assert_nil parser.parse("FOO")
    assert parser.parse("fOO")
    assert parser.parse("foo")
  end

  def test_optional_middle
    parser=new_parser do
      rule :foo, ["foo", :bar?, "foo"]
      rule :bar, ["bar"]
    end

    assert parser.parse("foofoo")
    assert parser.parse("foobarfoo")
  end

  def test_greedy_optional_middle
    parser=new_parser do
      rule :foo, ["foo", :bar?, "foo"]
      rule :bar, ["foo"]
    end

    assert_nil parser.parse("foofoo")
    assert parser.parse("foofoofoo")
  end

  def test_not
    parser=new_parser do
      rule :foo, ["foo", :bar!]
      rule :bar, ["bar"]
    end

    assert_nil parser.parse("foofud") # this should fail because it doesn't match the entire input
    assert parser.parse("foofud",0,:foo)
    assert parser.parse("foo")
    assert_nil parser.parse("foobar")
  end

  def test_recursive
    parser=new_parser do
      rule :foo, ["foo", :foo?]
    end

    assert parser.parse("foo")
    assert parser.parse("foofoo")
    assert f=parser.parse("foofoofoo")

#    assert_nil parser[:foo].parse("foobar")
  end

  def test_alternate
    v1=nil
    v2=nil
    parser=new_parser do
      v1=rule :foo, ["foo"]
      v2=rule :foo, ["bar"]
    end

    assert r1=parser.parse("foo")
    assert r2=parser.parse("bar")
    assert_equal v1,r1.class
    assert_equal v2,r2.class
  end

  def test_add
    parser=new_parser do
      rule :add, [:number,"+",:number]
      rule :number, [/[0-9]+/]
    end

    assert parser.parse("1+1")
    assert parser.parse("987+123")
  end

  def test_method
    parser=new_parser do
      rule :number, [/[0-9]+/] do
        def number
          text.to_i
        end
      end
    end

    assert p=parser.parse("123")
    assert_equal 123,p.number
  end

  def test_adder
    parser=new_parser do
      rule :adder, :number, "+", :number do
        def answer;
          number[0].number + number[1].number
        end
      end
      rule :number, /[0-9]+/ do
        def number; text.to_i end
      end
    end


    assert p=parser.parse("123+654")
    assert_equal 777,p.answer
  end

  def test_adder_multiplier
    parser=new_parser do

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

    assert_equal 123,parser.parse("123").value
    assert_equal 369,parser.parse("123*3").value
    assert_equal 370,parser.parse("123*3+1").value
    assert_equal 129,parser.parse("123+3*2").value
    assert_equal 777,parser.parse("123+654").value
    assert_equal 281,parser.parse("20*4+1+100*2").value
  end

  def test_rule_class
    parser=new_parser do
      rule :foo, "foo"
      rule :foo, "bar"
      node_class :foo do
        def value; text end
      end
    end

    assert_equal "foo",parser.parse("foo").value
    assert_equal "bar",parser.parse("bar").value
  end

  def test_indexed_match_reference_with_optional
    parser=new_parser do
      rule :foo, :bar, :boo?, :bar do
        def outter
          bar[0].text + bar[1].text
        end
      end
      rule :bar, /[0-9]+,?/
      rule :boo, /[A-Z]+,?/
    end

    assert_equal "1,2", parser.parse("1,2").outter
    assert_equal "1,3", parser.parse("1,A,3").outter

  end

  def test_verbose
    parser=new_parser do
      rule :foo, {:match=>"foo"}, {:match=>"bar",:optional=>true}
    end

    assert parser.parse("foo")
    assert parser.parse("foobar")
  end

  def test_custom_parser
    parser=new_parser do
      rule :foo, {:parser=>lambda do |parent_node|
        offset=parent_node.next
        src=parent_node.src

        # Note, the \A anchors the search at the beginning of the string
        if src[offset..-1].index(/\A[A-Z]+/)==0
          endpattern=$~.to_s
          if i=src.index(endpattern,offset+endpattern.length)
            BabelBridge::TerminalNode.new(parent_node,i+endpattern.length-offset,"endpattern")
          end
        end
      end}
    end

    assert parser.parse("END this is in the middle END")
    assert_equal "END this is in END",parser.parse("END this is in END the middle END",0,:foo).text
    assert_nil parser.parse("END this is in the middle EN")
    assert_nil parser.parse("    END this is in the middle END")
  end

  def test_poly
    parser=new_parser do
      rule :foo, many("foo").as(:foo)
    end
    assert_equal ["foo"], parser.parse("foo").foo.collect {|f| f.text}
    assert_equal ["foo","foo"], parser.parse("foofoo").foo.collect {|f| f.text}
    assert_equal ["foo","foo","foo"], parser.parse("foofoofoo").foo.collect {|f| f.text}
  end

  def test_poly_delimiter
    parser=new_parser do
      rule :foo, many("foo",/ +/).as(:foo)
    end
    assert_equal ["foo"], parser.parse("foo").foo.collect {|f| f.text}
    assert parser.parse("foo     foo")
    assert_equal ["foo","foo"], parser.parse("foo     foo").foo.collect {|f| f.text}
  end

  def test_poly_post_delimiter
    parser=new_parser do
      rule :foo, many?("foo",/ +/,true).as(:foo), match("end").as(:end)
    end

    assert_equal nil,parser.parse("end").foo
    assert_equal "end",parser.parse("end").end.to_s
    assert_equal nil,parser.parse(" end")
    assert_equal nil,parser.parse("foofoo end")
    assert_equal ["foo"], parser.parse("foo end").foo.collect {|f| f.text}
    assert_equal ["foo","foo"], parser.parse("foo     foo end").foo.collect {|f| f.text}
    assert_equal 5, parser.parse("foo   foo       foo foo  foo end").foo.length
  end

  def test_poly_optional_delimiter
    parser=new_parser do
      rule :foo, many(";",match?(/ +/))
    end
    assert parser.parse(";")
    assert parser.parse_and_puts_errors(";;")
    assert parser.parse(";    ;   ;")
  end

  def test_many
    assert_equal({:many=>";",:match=>true}, BabelBridge::Parser.many(";"))
  end

  def test_many?
    assert_equal({:many=>";", :optionally=>true, :match=>true}, BabelBridge::Parser.many?(";"))
  end

  def test_many!
    assert_equal({:many=>";", :dont=>true, :match=>true}, BabelBridge::Parser.many!(";"))
  end

  def test_match
    assert_equal({:match=>";"}, BabelBridge::Parser.match(";"))
  end

  def test_match?
    assert_equal({:match=>";",:optionally=>true}, BabelBridge::Parser.match?(";"))
  end

  def test_match!
    assert_equal({:match=>";",:dont=>true}, BabelBridge::Parser.match!(";"))
  end

  def test_dont
    assert_equal({:match=>";",:dont=>true}, BabelBridge::Parser.dont.match(";"))
  end

  def test_optionally
    assert_equal({:match=>";",:optionally=>true}, BabelBridge::Parser.optionally.match(";"))
  end

  def test_could
    assert_equal({:match=>";",:could=>true}, BabelBridge::Parser.could.match(";"))
  end

  def test_ignore_whitespace
    parser=new_parser do
      ignore_whitespace
      rule :pair, "foo", "bar"
    end
    assert parser.parse("foobar")
    assert parser.parse("foo   bar")
    assert parser.parse("foobar   ")
    assert parser.parse("foo bar     ")
  end

  def test_binary_operator_rule
    parser=new_parser do
      binary_operators_rule :bin_op, :int, ["**", [:/, :*], [:+, "-"]], :right_operators => ["**"] do
        def evaluate  
          "(#{left.evaluate}#{operator}#{right.evaluate})"
        end
      end
     
      rule :int, /[-]?[0-9]+/ do
        def evaluate; to_s; end
      end
    end
    assert_equal "(1+2)",     parser.parse("1+2").evaluate
    assert_equal "((1+2)+3)", parser.parse("1+2+3").evaluate
    assert_equal "(1+(2*3))", parser.parse("1+2*3").evaluate
    assert_equal "((1*2)+3)", parser.parse("1*2+3").evaluate
    assert_equal "(5**6)",    parser.parse("5**6").evaluate
    assert_equal "((1-2)+((3*4)/(5**6)))", parser.parse("1-2+3*4/5**6").evaluate
    assert_equal "(5**(6**7))", parser.parse("5**6**7").evaluate
  end

  def test_line_col
    assert_equal [1,1], "".line_col(0)
    assert_equal [1,1], " ".line_col(0)
    assert_equal [1,1], "a\nbb\nccc".line_col(0)
    assert_equal [1,2], "a\nbb\nccc".line_col(1)
    assert_equal [2,1], "a\nbb\nccc".line_col(2)
    assert_equal [2,2], "a\nbb\nccc".line_col(3)
    assert_equal [2,3], "a\nbb\nccc".line_col(4)
    assert_equal [3,1], "a\nbb\nccc".line_col(5)
    assert_equal [3,2], "a\nbb\nccc".line_col(6)
    assert_equal [3,3], "a\nbb\nccc".line_col(7)
    assert_equal [3,4], "a\nbb\nccc".line_col(8)
    assert_equal [3,4], "a\nbb\nccc".line_col(9)
  end

  def disabled_test_recursive_block
    # PEG does have this problem, so this isn't really an error
    # But maybe in the future we'll handle it better.
    # SBD: Disabled 2010-10-24
    parser=new_parser do
      rule :foo, :foo, ";"
      rule :foo, "-"

    end
    parser.parse "-"
  end



  def regex_performance
    parser=new_parser do
      rule :foo, many(:element)
      rule :element, /[0-9]+/
      rule :element, "a"
    end

    str=("a"*10000)+"1"
    start_time=Time.now
    res=parser.parse(str)
    end_time=Time.now
    puts "time for matching string of length #{str.length}: #{((end_time-start_time)*1000).to_i}ms"
    puts "parse tree size: #{res.element.length}"
    assert res
  end
end

tests=BBTests.new
tests.run_tests(ARGV.length>0 && ARGV)
