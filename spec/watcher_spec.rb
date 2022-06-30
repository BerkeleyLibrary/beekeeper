require 'beekeeper/watcher'
require 'docker'
require 'slack'

describe Beekeeper::Watcher do
  subject { Beekeeper::Watcher.new(slack) }

  let(:slack) { instance_double(Slack::Web::Client) }

  describe '#watch!' do
    context 'a container without labels' do
      before { @old_watchers = ENV.delete('BEEKEEPER_WATCHERS') }
      after { ENV['BEEKEEPER_WATCHERS'] = @old_watchers }

      it 'notifies default channels' do
        expect_docker_event new_event
        expect_slack_notifications %w(#devops-alerts)

        subject.watch!
      end
    end

    context 'a container with labels' do
      it 'notifies the correct channels' do
        expect_docker_event new_event(watchers: '@some-user,#some-channel')
        expect_slack_notifications %w(#some-channel @some-user)

        subject.watch!
      end
    end
  end

  def expect_slack_notifications(channels)
    channels.each do |channel|
      expect(slack)
        .to receive(:chat_postMessage)
        .once
        .ordered
        .with(hash_including(channel: channel))
    end
  end

  def expect_docker_event(event)
    expect(Docker::Event)
      .to receive(:stream)
      .and_yield(event)
  end

  def new_event(exit_code: 1, watchers: nil, service_name: nil)
    attrs = {
      'exitCode' => exit_code.to_s,
      'image' => 'containers.lib.berkeley.edu/lap/beekeeper:rspec-tests',
    }
    attrs['beekeeper.watchers'] = watchers if watchers
    attrs['com.docker.swarm.service.name'] = service_name if service_name

    Docker::Event.new(
      {
        Action: 'die',
        Actor: {
          ID: '12345',
          Attributes: attrs,
        },
      }
    )
  end
end
