require_relative './beekeeper/docker.rb'
require_relative './beekeeper/event.rb'
require_relative './beekeeper/slack_handler.rb'
require_relative './beekeeper/watcher.rb'

module Beekeeper
  def Beekeeper.watch!
    watcher = Beekeeper::Watcher.new
    watcher.watch!
  end
end
