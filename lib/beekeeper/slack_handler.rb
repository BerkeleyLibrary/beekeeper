require 'excon'
require 'json'

module Beekeeper
  class SlackHandler
    def initialize
      webhook_url_file = ENV.fetch('SLACK_WEBHOOK_URL_FILE', '/run/secrets/SLACK_WEBHOOK_URL')
      webhook_url = File.read(webhook_url_file)
      @connection = Excon.new(webhook_url,
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'})
    end

    def handle(event, docker)
      if event.service_failure?
        puts "Notifying event: #{event.inspect}"

        logs = docker.container_logs(event.actor_id)

        @connection.post(
          expects: [200, 201],
          body: JSON.dump({
            blocks: [
              {
                type: 'header',
                text: {
                  type: 'plain_text',
                  text: "\"#{event.service_name}\" exited non-zero",
                }
              },
              {
                type: 'section',
                fields: [
                  {
                    type: 'mrkdwn',
                    text: "*Swarm Node:*\n#{event.swarm_node_id}",
                  },
                  {
                    type: 'mrkdwn',
                    text: "*Service Name:*\n#{event.service_name}",
                  },
                  {
                    type: 'mrkdwn',
                    text: "*Container ID:*\n#{event.actor_id[..8]}",
                  },
                  {
                    type: 'mrkdwn',
                    text: "*Exit Code:*\n#{event.exit_code}",
                  },
                  {
                    type: 'mrkdwn',
                    text: "*Image:*\n#{simplify_image_name(event.from)}",
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
                  text: logs || '<logs not available>',
                },
              },
            ],
          }),
        )
      end
    end

    private

    def simplify_image_name(image_name)
      image_name
        .gsub('containers\.lib\.berkeley\.edu', '...') \
        .split('@')[0]
    end
  end
end
