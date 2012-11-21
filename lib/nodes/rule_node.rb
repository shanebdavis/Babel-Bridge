=begin
Copyright 2011 Shane Brinkman-Davis
See README for licence information.
http://babel-bridge.rubyforge.org/
=end

module BabelBridge
# rule node
# subclassed automatically by parser.rule for each unique non-terminal
class RuleNode < NonTerminalNode

  def match_names
    @match_names ||= []
  end

  def matches_by_name
    @matches_by_name||= begin
      raise "matches.length #{matches.length} != match_names.length #{match_names.length}" unless matches.length==match_names.length
      mbn={}
      mn=match_names
      matches.each_with_index do |match,i|
        name=mn[i]
        next unless name
        if current=mbn[name] # name already used
          # convert to MultiMatchesArray if not already
          mbn[name]=MultiMatchesArray.new([current]) if !current.kind_of? MultiMatchesArray
          # add to array
          mbn[name]<<match
        else
          mbn[name]=match
        end
      end
      mbn
    end
  end

  def inspect(options={})
    return "#{self.class}" if matches.length==0
    matches_inspected=matches.collect{|a|a.inspect(options)}.compact
    if matches_inspected.length==0 then nil
    elsif matches_inspected.length==1
      m=matches_inspected[0]
      ret="#{self.class} > "+matches_inspected[0]
      if options[:simple]
        ret=if m["\n"] then m
        else
          # just show the first and last nodes in the chain
          ret.gsub(/( > [A-Z][a-zA-Z0-9:]+ > (\.\.\. > )?)/," > ... > ")
        end
      end
      ret
    else
      (["#{self.class}"]+matches_inspected).join("\n").gsub("\n","\n  ")
    end
  end

  #********************
  # alter methods
  #********************
  def reset_matches_by_name
    @matches_by_name=nil
  end

  # defines where to forward missing methods to; override for custom behavior
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
    unless matches_by_name.has_key? method_name
      if f=forward_to(method_name)
        return f.send(method_name,*args)
      end
      match_path = [self]
      while match_path[-1].matches.length==1
        match_path<<match_path[-1].matches[0]
      end
      raise "#{match_path.collect{|m|m.class}.join(' > ')}: no methods or named pattern elements match: #{method_name.inspect}"
    end
    case ret=matches_by_name[method_name]
    when EmptyNode then nil
    else ret
    end
  end

  # adds a match with name (optional)
  def add_match(match,name=nil)
    reset_matches_by_name
    matches<<match
    match_names<<name

    update_match_length
  end
end
end
