require_relative './docker.rb'
require_relative './slack_handler.rb'

module Beekeeper
  class Watcher
    def initialize
      @docker = Beekeeper::Docker.new
      @handler = Beekeeper::SlackHandler.new
    end

    def watch!
      @docker.events do |event|
        @handler.handle(event, @docker)
      end
    end
  end
end