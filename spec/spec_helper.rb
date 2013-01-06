require File.join(File.dirname(__FILE__),"..","lib","babel_bridge")

module TestParserGenerator

  attr_accessor :parser

  def new_parser(&block)
    $parser_counter||=0
    $parser_counter+=1
    Object.const_set(klass_name="TestParser#{$parser_counter}",Class.new(BabelBridge::Parser,&block))
    @parser=Object.const_get(klass_name).new
  end

  #options
  #   :parser
  #   :failure_ok
  def test_parse(string,options={},&block)
    parser = options[:parser] || @parser
    res = parser.parse(string,options)
    yield res if res && block
    if options[:should_fail_at]
      res.should == nil
      parser.failure_index.should == options[:should_fail_at]
    elsif !options[:failure_ok]
      puts parser.parser_failure_info :verbose => true unless res
      res.should_not == nil
    end
    res
  end

end
