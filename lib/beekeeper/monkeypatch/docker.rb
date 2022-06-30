require 'docker'
require 'beekeeper/monkeypatch/docker/event'
require 'beekeeper/monkeypatch/docker/service'

module Docker
  class << self
    def setup_environment!
      Dir.glob('/run/secrets/*') do |filepath|
        secret_name = File.basename(filepath)
        secret_value = File.read(filepath).chomp
        ENV[secret_name] = secret_value unless secret_value.empty?
      end
    end
  end
end
