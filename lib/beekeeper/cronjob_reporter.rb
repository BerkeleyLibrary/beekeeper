require 'beekeeper/logging'
require 'beekeeper/monkeypatch/docker'
require 'docker'
require 'fugit'
require 'time'

module Beekeeper
  class CronjobReporter
    include Beekeeper::Logging

    ONE_DAY_IN_SECONDS = 3600 * 24

    def report(since: nil, filters: {})
      since ||= Time.now - ONE_DAY_IN_SECONDS

      filters[:label] ||= []
      filters[:label].append('swarm.cronjob.enable=true')

      {}.tap do |report|
        Docker::Service.all({ filters: }).each do |service|
          tasks = service.tasks

          # @note This is pretty slow, best to filter out known high-frequency jobs
          schedule = Fugit.parse_cron(service.label('swarm.cronjob.schedule'))
          scheduled_occurences = schedule.within(since...Time.now)

          report[service.name] = {
            id: service.id,
            name: service.name,
            schedule: schedule.original,
            count: tasks.size,
            scheduled_count: scheduled_occurences.size,
            completed: tasks.select(&:complete?).size,
            failed: tasks.select(&:failed?).size,
            rejected: tasks.select(&:rejected?).size,
            errors: tasks.collect(&:error).compact,
          }
        end
      end
    end
  end
end
