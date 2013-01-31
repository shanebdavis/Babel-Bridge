module BabelBridge
  module StringExtensions
    def camelize
      self.split("_").collect {|a| a.capitalize}.join
    end

    def first_lines(n)
      lines=self.split("\n",-1)
      lines.length<=n ? self : lines[0..n-1].join("\n")
    end

    def last_lines(n)
      lines=self.split("\n",-1)
      lines.length<=n ? self : lines[-n..-1].join("\n")
    end

  end
end

class String
  include BabelBridge::StringExtensions
end
