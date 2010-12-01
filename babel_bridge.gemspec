require File.join(File.dirname(__FILE__),"lib/babel_bridge.rb")

$gemspec = Gem::Specification.new do |s|
  s.name = "babel_bridge"
  s.version = BabelBridge::VERSION
  s.author = "Shane Brinkman-Davis"
  s.date = "2010-11-28"
  s.email = "shanebdavis@gmail.com"
  s.homepage = "http://babel-bridge.rubyforge.org"
  s.platform = Gem::Platform::RUBY
  s.rubyforge_project = "babel-bridge"
  s.summary = "A Ruby-based parser-generator based on Parsing Expression Grammars."
  s.description = "Babel Bridge let's you generate parsers 100% in Ruby code. It is a memoizing Parsing Expression Grammar (PEG) generator like Treetop, but it doesn't require special file-types or new syntax. Overall focus is on simplicity and usability over performance."
  s.files = ["LICENSE", "README", "Rakefile", "babel_bridge.gemspec", "{test,lib,doc,examples}/**/*"].map{|p| Dir[p]}.flatten
  s.has_rdoc = false
end