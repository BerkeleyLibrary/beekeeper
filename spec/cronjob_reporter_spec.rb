require 'beekeeper/cronjob_reporter'

describe Beekeeper::CronjobReporter, requires_docker: true do
  subject(:reporter) { Beekeeper::CronjobReporter.new }

  it 'reports on all tasks for all cronjob services' do
    report = reporter.report

    expect(report).to match(
      {
        "beekeeper_cron_job_exits_nonzero" => {
          id: a_kind_of(String),
          name: "beekeeper_cron_job_exits_nonzero",
          schedule: "*/10 * * * * *",
          scheduled_count: a_kind_of(Integer),
          count: a_kind_of(Integer),
          completed: a_kind_of(Integer),
          failed: a_kind_of(Integer),
          rejected: a_kind_of(Integer),
          errors: all(eq("task: non-zero exit (1)").or be_nil)
        },
        "beekeeper_cron_job_unscheduleable" => {
          id: a_kind_of(String),
          name: "beekeeper_cron_job_unscheduleable",
          schedule: "*/10 * * * * *",
          scheduled_count: be_between(8639, 8640),
          count: a_kind_of(Integer),
          completed: a_kind_of(Integer),
          failed: a_kind_of(Integer),
          rejected: a_kind_of(Integer),
          errors: all(eq("No such image: alpine:this-tag-does-not-exist").or be_nil)
        },
        "beekeeper_cron_job_exits_zero" => {
          id: a_kind_of(String),
          name: "beekeeper_cron_job_exits_zero",
          schedule: "*/10 * * * * *",
          scheduled_count: be_between(8639, 8640),
          count: a_kind_of(Integer),
          completed: a_kind_of(Integer),
          failed: a_kind_of(Integer),
          rejected: a_kind_of(Integer),
          errors: []
        }
      }
    )
  end

  it 'reports with additional label filters' do
    report = reporter.report(
      filters: {
        label: ['beekeeper.include_in_cronjob_report=true'],
      }
    )

    expect(report.keys).to eq %w(beekeeper_cron_job_exits_nonzero)
  end

  it 'reports with additional name filters' do
    report = reporter.report(
      filters: {
        name: ['beekeeper_cron_job_exits_'],
      }
    )

    expect(report.keys).to eq %w(
      beekeeper_cron_job_exits_nonzero
      beekeeper_cron_job_exits_zero
    )
  end

  it 'combines name and multiple label filters' do
    report = reporter.report(
      filters: {
        label: ['beekeeper.include_in_cronjob_report=true'],
        name: ['beekeeper_cron_job_exits_'],
      }
    )

    expect(report.keys).to eq %w(
      beekeeper_cron_job_exits_nonzero
    )
  end
end
