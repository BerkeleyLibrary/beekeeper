$LOAD_PATH << '../lib'

require 'simplecov'
SimpleCov.start do
  coverage_dir 'artifacts/coverage'
  minimum_coverage 0
end

require 'beekeeper'

RSpec.configure do |c|
  unless ENV['RSPEC_DOCKER'] && !ENV['RSPEC_DOCKER'].empty?
    c.filter_run_excluding requires_docker: true
  end
end
