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
