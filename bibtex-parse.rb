require "rubygems"
require "lib/babel_bridge.rb"
require "yaml"

class BibParser < BabelBridge::Parser
  rule :file, many(:entry) do
    def gather
      entry.collect {|a|a.gather}.compact
    end
  end

  rule :entry, "@", :entry_type, "{", :title, :delim, many(:field,:delim), /\}\s*/ do
    def fields
      retfields={}
      field.each do |f|
        k,v=f.to_kv
        retfields[k]=v
      end
      retfields
    end
    def gather
      {:entry_type => entry_type.to_s, :title => title.to_s, :fields =>fields}
    end
  end

  rule :entry, :comment do
    def gather
      #{:entry_type => :comment, :comment=>to_s}
    end
  end


  rule :comment, /%%[^\n]+\s*/

  rule :delim, /,\s*/
  rule :field, :field_key, /\s*=\s*/, :field_value do
    def to_kv
      return field_key.to_s,field_value.to_s
    end
  end

  rule :field_value, /[^{},]*/, "{", many(:field_part), "}"

  rule :field_part, "{", many(:field_part), "}"
  rule :field_part, /[^{}]+/

  rule :field_key, /[a-zA-Z]+/
  rule :title, /[:a-z0-9]+/
  rule :entry_type, /[a-z]+/
end

filename=ARGV[0]
puts filename
data=File.read(filename)

parser=BibParser.new

journal =
if res=parser.parse(data)
  puts "success in #{parser.parse_time} seconds"
else
  puts "Fail"
  puts parser.parser_failure_info
end

