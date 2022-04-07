require 'excon'
require 'json'
require_relative 'logging.rb'

module Beekeeper
  class Slack
    include Beekeeper::Logging

    def initialize(connection: nil)
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
    end

    def post_webhook(data)
      @connection.post(body: JSON.dump(data), expects: [200, 201])
    end
  end
end
