require 'beekeeper/monkeypatch/docker'
require 'beekeeper/logging'
require 'beekeeper/slack_notifier'
require 'beekeeper/watcher'

module Beekeeper
  include Beekeeper::Logging

  def Beekeeper.watch!
    watcher = Beekeeper::Watcher.new
    watcher.watch!
  end
end
