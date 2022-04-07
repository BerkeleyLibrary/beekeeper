require_relative 'docker.rb'
require_relative 'logging.rb'
require_relative 'slack_handler.rb'

module Beekeeper
  class Watcher
    include Beekeeper::Logging

    def initialize(docker: nil, handler: nil)
      docker ||= Beekeeper::Docker.new
      @docker = docker

      handler ||= Beekeeper::SlackHandler.new(docker: docker)
      @handler = handler
    end

    def watch!
      begin
        @docker.events do |event|
          begin
            @handler.handle(event)
          rescue => e
            error "Error handling an event, continuing: #{e.inspect}"
          end
        end
      rescue => e
        fatal "Unrecoverable error occurred reading Docker events, terminating: #{e.inspect}"
        raise
      end
    end
  end
end
