=begin
Copyright 2011 Shane Brinkman-Davis
See README for licence information.
http://babel-bridge.rubyforge.org/
=end

module BabelBridge
# rule node
# subclassed automatically by parser.rule for each unique non-terminal
class RuleNode < NonTerminalNode

  def initialize(parent, delimiter_pattern = nil)
    @num_match_attempts = 0
    @delimiter_pattern = delimiter_pattern
    super parent
  end

  def match_names
    @match_names ||= []
  end

  def match_name_is_poly(name)
    return unless name
    if current = matches_by_name[name]
      matches_by_name[name] = MultiMatchesArray.new([current]) if !current.kind_of? MultiMatchesArray
    else
      matches_by_name[name] = MultiMatchesArray.new
    end
  end

  def add_match_name(match,name)
    return unless name
    puts "add_match_name #{match.inspect}, #{name.inspect}"
    if current = matches_by_name[name]
      matches_by_name[name] = MultiMatchesArray.new([current]) if !current.kind_of? MultiMatchesArray
      matches_by_name[name] << match
    else
      matches_by_name[name] = match
    end
  end

  def matches_by_name
    @matches_by_name||={}
  end

  def inspect(options={})
    return relative_class_name if matches.length==0
    matches = @matches
    matches=matches.select{|m|!m.many_delimiter} unless options[:verbose]
    matches_inspected = matches.collect{|a|a.inspect(options)}.compact
    if matches_inspected.length==0 then nil
    elsif matches_inspected.length==1
      m = matches_inspected[0]
      ret = "#{relative_class_name} > "+matches_inspected[0]
      if options[:simple]
        ret = if m["\n"] then m
        else
          # just show the first and last nodes in the chain
          ret.gsub(/( > [A-Z][a-zA-Z0-9:]+ > (\.\.\. > )?)/," > ... > ")
        end
      end
      ret
    else
      (["#{relative_class_name}"]+matches_inspected).join("\n").gsub("\n","\n  ")
    end
  end

  #********************
  # alter methods
  #********************

  # returns where to forward missing methods calls to (safe to override for custom behavior; respond_to? and method_missing will "do the right thing")
  # returns nil if there is no object to forward to that will respond to the call
  # default: forward to the first match that responds to method_name
  def forward_to(method_name)
    matches.each {|m| return m if m.respond_to?(method_name)}
    nil
  end

  def respond_to?(method_name)
    super ||
    matches_by_name[method_name] ||
    forward_to(method_name)
  end

  def method_missing(method_name, *args)  #method_name is a symbol
    return matches_by_name[method_name] if matches_by_name.has_key?(method_name)

    if f = forward_to(method_name)
      return f.send(method_name,*args)
    end

    raise "#{path_string onlychildren_list}: no methods or named pattern elements match: #{method_name.inspect} on #{self.class} instance"
  end

  # adds a match with name (optional)
  def add_match(match,name=nil)
    puts "add_match #{match.inspect}, #{name.inspect}"
    return unless match
    return match if match==self

    add_match_name(super(match),name)

    update_match_length
    match
  end

  def pop_match
    matches.pop.tap {update_match_length;puts "#{self.class} match_range=#{match_range.inspect}"}
  end

  # Attempts to match the pattern_element starting at the end of what has already been matched
  # If successful, adds the resulting Node to matches.
  # returns nil on if pattern_element wasn't matched; non-nil if it was skipped or matched
  def match(pattern_element)
    @num_match_attempts += 1
    puts "@num_match_attempts =#{@num_match_attempts.inspect} pattern_element = #{pattern_element.inspect}"
    return :no_pattern_element unless pattern_element
    return :skipped if pattern_element.delimiter &&
      (
      if last_match
        last_match.delimiter       # don't match two delimiters in a row
      else
        @num_match_attempts > 1   # don't match a delimiter as the first element unless this is the first match attempt
      end
      )

    if result = pattern_element.parse(self)
      puts "#{self.class} matched: #{result.inspect} (#{{:result_class => result.class, :pattern_element => pattern_element }}) self==result ? #{self == result}"
      add_match result, pattern_element.name # success, but don't keep EmptyNodes
    end
  end

  def match_delimiter
    match @delimiter_pattern
  end

  # called after matching is done and it was a success
  # returns the node which is actually added to the parse tree
  def post_match_processing
    on_matched
    self
  end

  # a simple "transaction" - logs the curent number of matches,
  # if the block's result is false, it discards all new matches
  def attempt_match
    matches_before = matches.length
    match_length_before = match_length
    (yield && match_length > match_length_before).tap do |success|  # match_length test returns failure if no progress is made (our source position isn't advanced)
      unless success
        @matches = matches[0..matches_before-1]
        update_match_length
      end
    end.tap do
      puts "match_length = #{match_length} match_length_before = #{match_length_before}"
    end
  end

end
end
