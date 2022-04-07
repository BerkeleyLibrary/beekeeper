require_relative 'beekeeper/docker.rb'
require_relative 'beekeeper/docker_event.rb'
require_relative 'beekeeper/logging.rb'
require_relative 'beekeeper/slack.rb'
require_relative 'beekeeper/slack_handler.rb'
require_relative 'beekeeper/watcher.rb'

module Beekeeper
  include Beekeeper::Logging

  def Beekeeper.watch!
    watcher = Beekeeper::Watcher.new
    watcher.watch!
  end
end
