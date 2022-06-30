$LOAD_PATH << 'lib'

require 'dotenv/load'
require 'beekeeper'
require 'docker'

Docker.setup_environment!

begin
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new(:spec)
rescue LoadError
end

task default: %w[watch]

desc 'Watch for Docker events'
task :watch do
  Beekeeper.watch!
end

desc 'Open a pry Ruby console'
task :pry do
  exec 'pry -Ilib -r beekeeper'
end

desc 'Open a shell'
task :bash do
  exec 'bash'
end
