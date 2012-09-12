=begin
Copyright 2011 Shane Brinkman-Davis
See README for licence information.
http://babel-bridge.rubyforge.org/
=end

%w{
  tools
  string
  version
  nodes
  pattern_element
  shell
  rule_variant
  rule
  parser
}.each do |file|
  require File.join(File.dirname(__FILE__),file)  
end