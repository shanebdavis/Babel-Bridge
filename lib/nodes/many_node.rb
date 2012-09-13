=begin
Copyright 2011 Shane Brinkman-Davis
See README for licence information.
http://babel-bridge.rubyforge.org/
=end

module BabelBridge
  # generated by a :poly PatternElement
  # Not subclassed
  class ManyNode < Node
    attr_accessor :matches,:delimiter_matches
    def initialize(parent)
      node_init(parent)
      self.matches=[]
      self.delimiter_matches=[]
    end

    def match_length; self.next-offset end

    def next
      if m=matches[-1]
        m_next=m.next
        if d=delimiter_matches[-1]
          d_next=d.next
          m_next > d_next ? m_next : d_next
        else
          m_next
        end
      else
        parent.next
      end
    end

    def inspect_helper(list,options)
      simple=options[:simple]
      ret=list.collect {|a|a.inspect(options)}.compact
      ret= if ret.length==0 then simple ? nil : "[]"
      elsif ret.length==1 && !ret[0]["\n"] then (simple ? ret[0] : "[#{ret[0]}]")
      else 
        ret = ret.collect {|a| "  "+a.gsub("\n","\n  ")}
        (simple ? ret : ["[",ret,"]"]).flatten.join("\n") #.gsub("\n","\n  ")
      end
      ret
    end

    def inspect(options={})
      if options[:simple]
        c=[]
        matches.each_with_index {|n,i| c<<n;c<<delimiter_matches[i]}
        c=c.compact
        inspect_helper(c,options)
      else
        ret=inspect_helper(matches,options)
        ret+=" delimiters="+inspect_helper(delimiter_matches,options) if delimiter_matches.length>0
        ret
      end
    end

    def method_missing(method_name, *args)  #method_name is a symbol
      self.map {|match| match.send(method_name,*args)}
    end

  end
end
