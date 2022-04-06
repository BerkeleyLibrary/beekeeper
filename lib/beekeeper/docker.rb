require 'excon'
require_relative './event.rb'

module Beekeeper
  class Docker
    def events(&block)
      Excon.get('unix:///events',
        socket: '/var/run/docker.sock',
        read_timeout: nil,
        connect_timeout: nil,
        response_block: lambda { |data, _, _| yield Beekeeper::Event.new(data) },
      )
    end

    def container_logs(container_id, tail: 100)
      res = Excon.get("unix:///containers/#{container_id}/logs",
        query: {
          tail: tail,
          stdout: 'true',
          stderr: 'true',
        },
        socket: '/var/run/docker.sock',
      )
      res.body
    end
  end
end
