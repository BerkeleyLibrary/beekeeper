require 'beekeeper/logging'
require 'beekeeper/monkeypatch/docker'
require 'beekeeper/slack_notifier'
require 'docker'

module Beekeeper
  class Watcher
    include Beekeeper::Logging

    # Exit gracefully (0) when receiving these signals
    GRACEFUL_SIGNALS = %w(SIGHUP SIGINT SIGQUIT SIGTERM).freeze

    # Max time between events. Defaults to 0, meaning no timeout. If no events occur within
    # the timeout a Docker::Error::TimeoutError is raised and BeeKeeper reconnects. This should
    # still be avoided, as there is a race condition in which events could slip by unnoticed.
    MAX_TIME_BETWEEN_EVENTS = ENV.fetch('READ_TIMEOUT', 0).to_i

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

    attr_reader :slack

    def initialize(slack = Beekeeper::SlackNotifier.new)
      @slack = slack
    end

    def clean_watchlist(watchlist)
      watchlist
        .map(&:strip)
        .select(&method(:valid_channel?))
        .sort
        .uniq
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
      if event.failure?
        debug "Notifying failure event: #{event.inspect}"

        get_event_watchers(event).each do |recipient|
          notify! recipient, event
        rescue => e
          error "Handling error: #{e.inspect}"
          error e.backtrace.join($/)
        end
      else
        debug "Ignoring non-failure event: #{event.inspect}"
      end
    end

    def notify!(recipient, event)
      slack.notify_failure_event(event:, recipient:)
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
