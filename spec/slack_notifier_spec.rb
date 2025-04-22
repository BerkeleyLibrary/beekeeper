require 'beekeeper/slack_notifier'
require 'docker'
require 'slack'

describe Beekeeper::SlackNotifier do
  let(:client) { instance_double(Slack::Web::Client) }
  subject(:notifier) { Beekeeper::SlackNotifier.new(client) }

  describe 'sending event notifications' do
    context 'for a failed container' do
      it 'sends a well-formed chat message' do
        event = new_event(exit_code: 11)
        recipient = '#devops-alerts'

        expect(client)
          .to receive(:chat_postMessage)
          .with hash_including({
            channel: recipient,
            blocks: array_including(hash_including({
              type: 'header',
              text: {
                type: 'plain_text',
                text: "Container '12345' exited 11"
              }
            }))
          })

        notifier.notify_failure_event event:, recipient:
      end
    end
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
