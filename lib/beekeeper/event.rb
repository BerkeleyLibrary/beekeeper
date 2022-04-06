require 'time'

module Beekeeper
  class Event
    def initialize(event_data)
      @data = event_data.kind_of?(String) ? JSON.parse(event_data) : event_data
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

    def service_name
      attributes['com.docker.swarm.service.name']
    end

    def swarm_node_id
      attributes['com.docker.swarm.node.id']
    end

    def time
      Time.at(@data['time'])
    end

    def died?
      @data['Action'] == 'die'
    end

    def container?
      @data['Type'] == 'container'
    end

    def failed?
      container? and died? and exit_code != '0'
    end
  end
end
