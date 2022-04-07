require 'excon'
require_relative './event.rb'

module Beekeeper
  class Docker
    include Beekeeper::Logging

    def events(&block)
      get('events',
        query: {
          format: '{{json .}}',
        },
        read_timeout: nil,
        connect_timeout: nil,
        response_block: lambda { |data, _, _| yield Beekeeper::Event.new(data) },
      )
    end

    def container_logs(container_id, truncate: false)
      logs = get("containers/#{container_id}/logs",
        parse: false,
        query: {
          tail: 100,
          stdout: 'true',
          stderr: 'true',
        },
      )

      if truncate and logs.length > truncate
        logs = logs[-truncate..-1]
      end

      logs
    end

    def inspect_node(node_id)
      get("nodes/#{node_id}")
    end

    private

    def get(path, parse: true, **kwargs)
      res = Excon.get(
        "unix:///#{path}",
        socket: '/var/run/docker.sock',
        **kwargs,
      )
      parse ? JSON.parse(res.body) : res.body
    end
  end
end
