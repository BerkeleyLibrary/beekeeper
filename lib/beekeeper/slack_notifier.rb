require 'slack'

module Beekeeper
  class SlackNotifier
    # Name of the environment variable containing the string value of
    # the Slack API/OAuth token.
    SLACK_TOKEN_ENV = 'SLACK_API_TOKEN'.freeze

    # Name of the environment variable containing the path to file
    # containing the value of the Slack token. This is used only if
    # SLACK_TOKEN_ENV is empty.
    SLACK_TOKEN_FILE_ENV = 'SLACK_API_TOKEN_FILE'.freeze

    # Default path to the file that should contain the Slack token, if
    # SLACK_TOKEN_ENV and SLACK_TOKEN_FILE_ENV are not set.
    SLACK_TOKEN_DEFAULT_FILE = '/run/secrets/SLACK_API_TOKEN'.freeze

    attr_reader :client

    def initialize(client = default_client)
      @client = client
    end

    def notify_event(event:, recipient:)
      subject = event.service_name \
        ? "Service \"#{event.service_name}\" exited #{event.exit_code}"
        : "Container '#{event.actor.id[..7]}' exited #{event.exit_code}"

      @client.chat_postMessage(
        channel: recipient,
        as_user: true,
        blocks: [
          { type: 'header', text: { type: 'plain_text', text: subject } },
          # Event Summary
          { type: 'section', fields: [{
              'Host Name'    => Docker.info['Name'],
              'Swarm Node'   => event.swarm_node_id,
              'Service Name' => event.service_name,
              'Container ID' => event.actor_short_id,
              'Exit Code'    => event.exit_code,
              'Image'        => event.image_shortname,
            }.map { |h, t| { type: 'mrkdwn', text: "*#{h}*: #{t}" } }
          ]},
          # Container Logs (if available)
          { type: 'section', text: { type: 'mrkdwn', text: '*Logs:*' } },
          { type: 'section', text: { type: 'plain_text', text: event.get_logs } },
        ],
      )
    end

    private

    def default_client
      Slack::Web::Client.new(token: default_token).tap do |client|
        client.auth_test
      end
    end

    def default_token
      ENV.fetch(SLACK_TOKEN_ENV) do
        File.read(ENV[SLACK_TOKEN_FILE_ENV] || SLACK_TOKEN_DEFAULT_FILE).chomp
      end
    end
  end
end
