require_relative 'docker.rb'
require_relative 'logging.rb'
require_relative 'slack.rb'

module Beekeeper
  class SlackHandler
    include Beekeeper::Logging

    def initialize(docker: nil, slack: nil)
      docker ||= Beekeeper::Docker.new
      @docker = docker

      slack ||= Beekeeper::Slack.new
      @slack = slack
    end

    def handle(event)
      return unless event.service_failure?

      debug "Notifying event: #{event.inspect}"

      logs = @docker.container_logs(event.actor_id, truncate: 5000)

      @slack.post_webhook({
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
                text: "*Container ID:*\n#{event.actor_id[..7]}",
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
      })
    end
  end
end
