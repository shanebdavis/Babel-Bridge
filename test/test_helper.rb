class TestHelper
  class AssertionFailure < Exception
  end
  def assert(val)
    raise AssertionFailure.new("assertion failed: expected a value, got #{val.inspect}") unless val
  end

  def assert_nil(val)
    raise AssertionFailure.new("assertion failed: did not expect a value, got #{val.inspect}") if val
  end

  def assert_equal(expected,val)
    raise AssertionFailure.new("expected #{expected.inspect}; got #{val.inspect}") if expected!=val
  end

  def run_tests(tests=nil)
    failures=[]
    errors=[]
    successes=0
    (tests || self.methods).each do |method|
      method=method.to_sym
      if method.to_s[/^test_/]
        begin
          self.send(method)
          successes+=1
          $stdout.write(".");
        rescue AssertionFailure => e
          errors<<"#{method} failed an assertion: #{e}"+
          "    "+e.backtrace.join("\n    ")+"\n\n"
          $stdout.write("E");
        rescue Exception => e
          failures<<"#{method} had an error: #{e}"+
          "    "+e.backtrace.join("\n    ")+"\n\n"
          $stdout.write("F");
        end
        $stdout.flush()
      end
    end
    puts ""
    puts "\n\n"+(errors+failures).join("\n\n")
    puts "successes: #{successes}, failures: #{failures.length}, errors: #{errors.length}"
  end
end

