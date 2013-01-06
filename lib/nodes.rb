%w{
  node
  empty_node
  terminal_node
  non_terminal_node
  rule_node
  root_node
}.each do |file|
  require File.join(File.dirname(__FILE__),"nodes",file)
end
