$LOAD_PATH << '../lib'

require 'simplecov'
SimpleCov.start do
  coverage_dir 'artifacts/coverage'
  minimum_coverage 90
end

require 'beekeeper'
require 'rspec/file_fixtures'
