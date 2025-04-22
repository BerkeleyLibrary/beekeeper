require 'beekeeper/logging'
require 'beekeeper/monkeypatch/docker'
require 'docker'
require 'slack'

module Beekeeper
  class Watcher
    include Beekeeper::Logging

    # Exit gracefully (0) when receiving these signals
    GRACEFUL_SIGNALS = %w(SIGHUP SIGINT SIGQUIT SIGTERM).freeze

    # Max time between events. Defaults to 0, meaning no timeout. If no events occur within
    # the timeout a Docker::Error::TimeoutError is raised and BeeKeeper reconnects. This should
    # still be avoided, as there is a race condition in which events could slip by unnoticed.
    MAX_TIME_BETWEEN_EVENTS = ENV.fetch('READ_TIMEOUT', 0).to_i

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

    def initialize(slack = nil)
      @slack = slack || default_slack_client
    end

    def clean_watchlist(watchlist)
      watchlist
        .map(&:strip)
        .select(&method(:valid_channel?))
        .sort
        .uniq
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

      @slack.chat_postMessage(
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

    def stream_options
      {
        nonblock: false,
        persistent: true,
        read_timeout: MAX_TIME_BETWEEN_EVENTS,
      }
    end

    def valid_channel?(channel)
      channel.start_with?('@', '#')
    end

    def watch!
      begin
        Docker::Event.stream(stream_options, &method(:handle))
      rescue SignalException => e
        error "Received #{e.signm}"
        raise unless GRACEFUL_SIGNALS.include? e.signm
        error "Exiting gracefully"
        exit 0
      rescue Docker::Error::TimeoutError => e
        error "Read timeout, reconnecting to docker /events: #{e}"
        retry
      end
    end
  end
end
