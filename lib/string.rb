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

    # return the line and column of a given offset into this string
    # line and column are 1-based
    def line_col(offset)
      return 1,1 if length==0 || offset==0
      lines=(self[0..offset-1]+" ").split("\n")
      return lines.length, lines[-1].length
    end
  end
end
 
class String
  include BabelBridge::StringExtensions
end