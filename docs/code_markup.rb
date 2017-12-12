require "rubygems"
require "babel_bridge"

class CodeMarkup < BabelBridge::Parser
  rule :file, many(:element) do
    def markup
      "<pre><code>"+
      element.collect{|a| a.markup}.join.strip+
      "</code></pre>"
    end
  end

  rule :element, "<", :space do
    def markup; "<symbol>&lt;</symbol>#{space}" end
  end

  rule :element, ">", :space do
    def markup; "<symbol>&gt;</symbol>#{space}" end
  end

  rule :element, :comment, :space do
    def markup; "<comment>#{comment}</comment>#{space}" end
  end

  rule :element, :keyword, :space do
    def markup; "<keyword>#{keyword}</keyword>#{space}" end
  end

  rule :element, :string, :space do
    def markup
      str=string.to_s.gsub("<","&lt;").gsub(">","&gt;")
      "<string>#{str}</string>#{space}"
    end
  end

  rule :element, :regex, :space do
    def markup; "<regex>#{regex}</regex>#{space}" end
  end

  rule :element, :identifier, :space do
    def markup; "<identifier>#{identifier}</identifier>#{space}" end
  end

  rule :element, :symbol, :space do
    def markup; "<symbol>#{symbol}</symbol>#{space}" end
  end

  rule :element, :number, :space do
    def markup; "<number>#{number}</number>#{space}" end
  end

  rule :element, :non_space, :space do
    def markup; "#{non_space}#{space}" end
  end

  rule :element, /\s+/ do
    def markup; to_s; end
  end

  rule :space, /\s*/
  rule :number, /[0-9]+(\.[0-9]+)?/
  rule :comment, /#[^\n]*/
  rule :string, /"(\\.|[^\\"])*"/
  rule :string, /:[_a-zA-Z0-9]+[?!]?/
  rule :regex, /\/(\\.|[^\\\/])*\//
  rule :symbol, /[-!@\#$%^&*()_+={}|\[\];:<>\?,\.\/~]+/
  rule :keyword, /class|end|def|and|or|do|if|then/, could.match(/[^a-zA-Z_0-9]/)
  rule :keyword, /else|elsif|case|then|when|require/, could.match(/[^a-zA-Z_0-9]/)
  rule :non_indentifier, match!(:identifier)
  rule :identifier, /[_a-zA-Z][0-9_a-zA-Z]*/
  rule :non_space, /[^\s]+/
end

def unmarkup(code)
  code.gsub(/<[^<>]+>/,"").gsub("&lt;","<").gsub("&gt;",">").gsub("&amp;","&")
end

def markup_html(html)
  precode=html.split(/<code><pre>|<pre><code>/)
  parser=CodeMarkup.new;
  precode[0]+precode[1..-1].collect do |pc|
    code,rest=pc.split(/<\/code><\/pre>|<\/pre><\/code>/)

    code = unmarkup(code)
    code=parser.parse(code)
    if !code
      $stderr.puts parser.parser_failure_info
      raise "parse failed"
    end
    code=code.markup
    code+rest
  end.join
end

def show_usage
  puts <<ENDUSAGE
Takes an HTML file and applys a ruby-based syntax markup to call text between <code><pre> and </pre></code>

Usage:
  #{__FILE__} source_html_file [dest_file]
ENDUSAGE
  exit 1
end

filename=ARGV[0]
show_usage unless filename
out_filename=ARGV[1]
#puts CodeMarkup.new.parse(File.read(ARGV[0])).markup
out=markup_html(File.read(ARGV[0]))
if out_filename
  File.open(out_filename,"w") {|f| f.write(out)}
else
  puts out
end
