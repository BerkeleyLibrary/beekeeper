require 'excon'
require 'json'
require_relative 'logging.rb'

module Beekeeper
  class Slack
    include Beekeeper::Logging

    def initialize(connection: nil)
      connection ||= Excon.new(webhook_url)
      connection.data[:headers].merge!({
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      })
      @connection = connection

      debug "Initialized Slack client"
    end

    def post_webhook(data)
      @connection.post(body: JSON.dump(data), expects: [200, 201])
    end

    private

    def webhook_url
      @webhook_url ||= begin
        if ENV.key? 'SLACK_WEBHOOK_URL'
          ENV['SLACK_WEBHOOK_URL']
        else
          secret_file = ENV.fetch('SLACK_WEBHOOK_URL_FILE', '/run/secrets/SLACK_WEBHOOK_URL')
          if File.exist? secret_file
            File.read secret_file
          else
            raise "The Slack client requires a webhook URL. Either set ENV['SLACK_WEBHOOK_URL'] " +
                  "to its value, or place it in a file specified by ENV['SLACK_WEBHOOK_URL_FILE'] " +
                  "or at /run/secrets/SLACK_WEBHOOK_URL."
          end
        end
      end
    end
  end
end
