require 'docker'
require 'beekeeper/monkeypatch/docker/service'

class Docker::Event
  def actor_short_id
    actor.id[0..7]
  end

  def exit_code
    @exit_code ||= actor.attributes['exitCode'].to_i
  end

  def failure?
    action == 'die' && exit_code != 0
  end

  def image_shortname
    img, sha = actor.attributes['image'].split('@')
    if sha
      "#{img}@#{sha[0..7]}"
    else
      img
    end
  end

  def get_logs(tail = 100)
    begin
      Docker::Container.get(actor.id).logs(
        tail: tail,
        stdout: true,
        stderr: true
      ).encode('UTF-8', invalid: :replace, undef: :replace, replace: '?')
    rescue Encoding::UndefinedConversionError
      '<encoding error: check CloudWatch for raw log data>'
    rescue
      nil
    end
  end

  def paused?
    # @note In this case, the actor seems to be the service. For more information,
    #   you'll have to get the service (via actor.id), parse its UpdateStatus.Message
    #   for the task ID (/task (\w+)$/), then get that task and inspect its Status.Err.
    attributes['updatestate.new'] == 'paused' rescue false
  end

  def service
    @service ||= Docker::Service.get(service_name)
  end

  def service_name
    @service_name ||= begin
      if type == 'service'
        attributes['name']
      else
        actor.attributes['com.docker.swarm.service.name']
      end
    end
  end

  def service_related?
    actor.attributes.key? 'com.docker.swarm.service.id'
  end

  def swarm_node_id
    @swarm_node_id ||= begin
      actor.attributes.fetch('com.docker.swarm.node.id') do
        Docker.info['Swarm']['NodeID'] rescue nil
      end
    end
  end
end
