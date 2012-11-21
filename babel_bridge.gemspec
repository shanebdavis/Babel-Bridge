require File.join(File.dirname(__FILE__),"lib/babel_bridge.rb")

$gemspec = Gem::Specification.new do |gem|
  gem.name = "babel_bridge"
  gem.version = BabelBridge::VERSION
  gem.author = "Shane Brinkman-Davis"
  gem.date = "2010-11-28"
  gem.email = "shanebdavis@gmail.com"
  gem.homepage = "http://babel-bridge.rubyforge.org"
  gem.platform = Gem::Platform::RUBY
  gem.rubyforge_project = "babel-bridge"
  gem.summary = "A Ruby-based parser-generator based on Parsing Expression Grammars."
  gem.description = <<DESCRIPTION
Babel Bridge is an object oriented parser generator for parsing expression grammars (PEG).
Generate memoizing packrat parsers 100% in Ruby code with a simple embedded DSL.
DESCRIPTION

  gem.files = ["LICENSE", "README", "Rakefile", "babel_bridge.gemspec", "{test,spec,lib,doc,examples}/**/*"].map{|p| Dir[p]}.flatten
  gem.has_rdoc = false

  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'rspec'
end
