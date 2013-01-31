module BabelBridge
# hash which can be used declaratively
class PatternElementHash
  attr_accessor :hash

  def initialize
    @hash = {}
  end

  def inspect; hash.inspect; end

  def [](key) @hash[key] end
  def []=(key,value) @hash[key]=value end

  def method_missing(method_name, *args)  #method_name is a symbol
    return self if args.length==1 && !args[0] # if nil is provided, don't set anything
    raise "More than one argument is not supported. #{self.class}##{method_name} args=#{args.inspect}" if args.length > 1
    @hash[method_name] = args[0] || true # on the other hand, if no args are provided, assume true
    self
  end
end
end
