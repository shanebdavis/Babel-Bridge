require "bundler/gem_tasks"
require "rspec/core/rake_task"

task :default => :spec

desc "Run specs"
RSpec::Core::RakeTask.new do |task|
    task.pattern = "**/spec/*_spec.rb"
    task.rspec_opts = Dir.glob("[0-9][0-9][0-9]_*").collect { |x| "-I#{x}" }.sort
    task.rspec_opts << '--color'
    task.rspec_opts << '-f documentation'
end
