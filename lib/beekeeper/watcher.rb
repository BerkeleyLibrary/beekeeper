require 'beekeeper/logging'
require 'beekeeper/monkeypatch/docker'
require 'docker'
require 'slack'

module Beekeeper
  class Watcher
    include Beekeeper::Logging

    # Comma-separated list of Slack channels/users. If a container or
    # service fails and does not have its own custom watchers, these
    # are notified.
    WATCHERS_DEFAULT = '#devops-alerts'.freeze

    # Name of the environment variable that, if it exists, sets the
    # default watchlist.
    WATCHERS_ENV = 'BEEKEEPER_WATCHERS'.freeze

    # The Container/Service label containing the comma-separated list
    # of watchers for the service.
    WATCHERS_LABEL = 'beekeeper.watchers'.freeze

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

    # Max number of times to retry streaming events before giving up and raising
    MAX_RETRIES = 10

    def initialize(slack = nil)
      @slack = slack || default_slack_client
    end

    def watch!
      tries = 0
      begin
        Docker::Event.stream({ nonblock: false, persistent: true, read_timeout: nil }) { |e| handle e }
      rescue => e
        error "Error while streaming Docker events, retrying: #{e.inspect}"
        tries += 1
        tries <= MAX_RETRIES ? retry : raise
      end
    end

    def handle(event)
      unless event.failure?
        debug "Ignoring non-failure event: #{event.inspect}"
        return
      end

      debug "Notifying event: #{event.inspect}"

      get_event_watchers(event).each do |recipient|
        notify! recipient, event
      rescue => e
        error "Handling error: #{e.inspect}"
        error e.backtrace.join($/)
      end
    end

    def notify!(recipient, event)
      subject = event.service_name \
        ? "Service \"#{event.service_name}\" exited #{event.exit_code}"
        : "Container '#{event.actor.id[..7]}' exited #{event.exit_code}"

      logs = begin
        Docker::Container.get(event.actor.id).logs(
          tail: 100,
          stdout: true,
          stderr: true
        ).encode('UTF-8', invalid: :replace, undef: :replace, replace: '?')
      rescue Encoding::UndefinedConversionError
        '<encoding error: check CloudWatch for raw log data>'
      rescue
        '<no log data>'
      end

      @slack.chat_postMessage(
        channel: recipient,
        as_user: true,
        blocks: [
          {
            type: 'header',
            text: {
              type: 'plain_text',
              text: subject,
            }
          },
          {
            type: 'section',
            fields: [
              {
                type: 'mrkdwn',
                text: "*Swarm Node:*\n#{event.swarm_node_id || 'N/A'}",
              },
              {
                type: 'mrkdwn',
                text: "*Service Name:*\n#{event.service_name || 'N/A'}",
              },
              {
                type: 'mrkdwn',
                text: "*Container ID:*\n#{event.actor.id}",
              },
              {
                type: 'mrkdwn',
                text: "*Exit Code:*\n#{event.exit_code}",
              },
              {
                type: 'mrkdwn',
                text: "*Image:*\n#{event.image_shortname}",
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
              text: logs,
            },
          },
        ],
      )
    end

    def get_event_watchers(event)
      watchers = []

      # Service watchers...
      watchers += event.service.service_label(WATCHERS_LABEL, '').split(',') \
        if event.service_related?

      # Container watchers...
      watchers += event.actor.attributes.fetch(WATCHERS_LABEL, '').split(',')

      # Fallback if no custom watchers...
      watchers += default_watchers if watchers.empty?

      # De-duplicate / ensure (apparent) validity
      clean_watchlist(watchers).tap { |w| debug "Notifying #{w}" }
    end

    def clean_watchlist(watchlist)
      watchlist
        .map(&:strip)
        .select(&method(:valid_channel?))
        .sort
        .uniq
    end

    def valid_channel?(channel)
      channel.start_with?('@', '#')
    end

    def default_slack_client
      Slack::Web::Client.new(token: default_slack_token).tap do |client|
        client.auth_test
      end
    end

    def default_slack_token
      ENV.fetch(SLACK_TOKEN_ENV) do
        File.read(ENV[SLACK_TOKEN_FILE_ENV] || SLACK_TOKEN_DEFAULT_FILE).chomp
      end
    end

    def default_watchers
      ENV.fetch(WATCHERS_ENV, WATCHERS_DEFAULT).split(',')
    end
  end
end
