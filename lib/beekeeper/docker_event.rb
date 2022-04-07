require 'time'
require_relative 'logging.rb'

module Beekeeper
  class DockerEvent
    include Beekeeper::Logging

    def initialize(data)
      @data = data.kind_of?(String) ? JSON.parse(data) : data
    end

    def actor_id
      @data['Actor']['ID']
    end

    def attributes
      @data['Actor']['Attributes']
    end

    def exit_code
      attributes['exitCode']
    end

    def from
      @data['from']
    end

    def simplified_image_name
      from
        .gsub('containers.lib.berkeley.edu', '...') \
        .split('@')[0]
    end

    def service_name
      attributes['com.docker.swarm.service.name']
    end

    def swarm_node_id
      attributes['com.docker.swarm.node.id']
    end

    def time
      Time.at(@data['time'])
    end

    def container?
      @data['Type'] == 'container'
    end

    def died?
      @data['Action'] == 'die'
    end

    def failed?
      container? and died? and exit_code != '0'
    end

    def service_failure?
      swarm_service? and failed?
    end

    def swarm_service?
      attributes.key? 'com.docker.swarm.service.id'
    end
  end
end
