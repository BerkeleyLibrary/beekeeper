describe Beekeeper::SlackHandler do
  subject { Beekeeper::SlackHandler.new(docker: docker, slack: slack) }
  let(:docker) { instance_double(Beekeeper::Docker) }
  let(:slack) { instance_double(Beekeeper::Slack) }

  describe '#handle' do
    it 'notifies on service failure events' do
      expect(docker).to receive(:container_logs)
        .with('615e666450d86dfed3d2fe07f6192e6d8772062cc237f820511acd52f6a4629c', truncate: 5000)
        .and_return('some logs')
      expect(slack).to receive(:post_webhook).with({
        blocks: [
          {
            type: 'header',
            text: {
              type: 'plain_text',
              text: '"fail-test" exited non-zero',
            }
          },
          {
            type: 'section',
            fields: [
              {
                type: 'mrkdwn',
                text: "*Swarm Node:*\nm9y7iknzbpo84yd1mw0t71m6m",
              },
              {
                type: 'mrkdwn',
                text: "*Service Name:*\nfail-test",
              },
              {
                type: 'mrkdwn',
                text: "*Container ID:*\n615e6664",
              },
              {
                type: 'mrkdwn',
                text: "*Exit Code:*\n1",
              },
              {
                type: 'mrkdwn',
                text: "*Image:*\n.../lap/ruby:3.0.3-slim",
              },
            ],
          },
          {
            type: 'section',
            text: {
              type: 'mrkdwn',
              text: '*Logs:*',
            },
          },
          {
            type: 'section',
            text: {
              type: 'plain_text',
              text: 'some logs',
            },
          },
        ],
      })

      event = Beekeeper::DockerEvent.new(fixture('service_failure_event.json').read)
      subject.handle(event)
    end

    it 'ignores non-service failure events' do
      expect(slack).not_to receive(:post_webhook)

      event = Beekeeper::DockerEvent.new(fixture('disconnect_event.json').read)
      subject.handle(event)
    end
  end
end
