require 'beekeeper/watcher'
require 'docker'
require 'slack'

describe Beekeeper::Watcher do
  let(:notifier) { instance_double(Beekeeper::SlackNotifier) }
  subject(:watcher) { Beekeeper::Watcher.new(notifier) }

  describe 'watching failure events' do
    context 'for an unlabeled container' do
      before { @old_watchers = ENV.delete('BEEKEEPER_WATCHERS') }
      after { ENV['BEEKEEPER_WATCHERS'] = @old_watchers }

      it 'notifies default channels' do
        event = new_event
        recipients = %w(#devops-alerts)
        expect_docker_event event
        expect_event_notification(event:, recipients:)

        watcher.watch!
      end
    end

    context 'for a container with labels' do
      it 'notifies the correct channels' do
        recipients = %w(#some-channel @some-user)
        event = new_event(watchers: recipients)
        expect_docker_event event
        expect_event_notification(event:, recipients:)

        watcher.watch!
      end
    end
  end

  private

  def expect_docker_event(event)
    expect(Docker::Event)
      .to receive(:stream)
      .and_yield(event)
  end

  def expect_event_notification(event:, recipients:)
    recipients.each do |recipient|
      expect(notifier)
        .to receive(:notify_event)
        .with(event:, recipient:)
    end
  end

  def new_event(exit_code: 1, watchers: nil, service_name: nil)
    attrs = {
      'exitCode' => exit_code.to_s,
      'image' => 'containers.lib.berkeley.edu/lap/beekeeper:rspec-tests',
    }
    attrs['beekeeper.watchers'] = watchers.join(',') if watchers
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
