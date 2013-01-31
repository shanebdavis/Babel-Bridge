lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'babel_bridge/version'

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

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'rspec'
  gem.add_development_dependency 'simplecov'
  gem.add_development_dependency 'guard-rspec'
  gem.add_development_dependency 'guard-test'
  gem.add_development_dependency 'rb-fsevent'
end
