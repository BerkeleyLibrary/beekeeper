require 'forwardable'

module Beekeeper
  module Logging
    extend Forwardable

    def logger
      Beekeeper::Logging.logger
    end

    def_delegators :logger, :info, :debug, :warn, :error, :fatal

    def self.logger
      @logger ||= begin
        $stdout.sync = true
        Logger.new(STDOUT)
      end
    end

    def self.logger=(logger)
      @logger = logger
    end
  end
end
