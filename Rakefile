require_relative 'lib/beekeeper.rb'

task default: %w[watch]

desc 'Watch for Docker events'
task :watch do
  Beekeeper.watch!
end

begin
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new(:spec)
rescue LoadError
end

desc 'Open a console'
task :console do
  exec 'pry -Ilib -r beekeeper'
end
task :c => :console
