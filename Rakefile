require_relative 'lib/beekeeper.rb'

task default: %w[watch]

desc 'Watch for Docker events'
task :watch do
  Beekeeper.watch!
end

desc 'Run the test suite'
task :spec do
  ruby 'rspec'
end
