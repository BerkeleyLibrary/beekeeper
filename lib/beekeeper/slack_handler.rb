require 'excon'
require 'json'

module Beekeeper
  class SlackHandler
    include Beekeeper::Logging

    def initialize(docker: nil, connection: nil)
      if connection.nil?
        webhook_url_file = ENV.fetch('SLACK_WEBHOOK_URL_FILE', '/run/secrets/SLACK_WEBHOOK_URL')
        webhook_url = File.read(webhook_url_file)
        connection = Excon.new(webhook_url)
      end

      connection.data[:headers].merge!({
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      })

      @connection = connection

      if docker.nil?
        docker = Beekeeper::Docker.new
      end

      @docker = docker
    end

    def handle(event)
      return unless event.service_failure?

      debug "Notifying event: #{event.inspect}"

      logs = @docker.container_logs(event.actor_id, truncate: 5000)

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
                  text: "*Image:*\n#{event.simplified_image_name}",
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
end
