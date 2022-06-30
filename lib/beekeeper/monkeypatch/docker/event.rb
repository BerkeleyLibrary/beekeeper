require 'docker'
require 'beekeeper/monkeypatch/docker/service'

class Docker::Event
  def exit_code
    @exit_code ||= actor.attributes['exitCode'].to_i
  end

  def image_shortname
    actor.attributes['image'].split('@').first
  end

  def service
    @service ||= Docker::Service.get(service_name)
  end

  def service_name
    @service_name ||= actor.attributes['com.docker.swarm.service.name']
  end

  def swarm_node_id
    @swarm_node_id ||= begin
      actor.attributes.fetch('com.docker.swarm.node.id') do
        Docker.info['Swarm']['NodeID'] rescue nil
      end
    end
  end

  def failure?
    action == 'die' && exit_code != 0
  end

  def service_related?
    actor.attributes.key? 'com.docker.swarm.service.id'
  end
end
