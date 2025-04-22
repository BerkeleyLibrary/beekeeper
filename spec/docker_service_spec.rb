require 'beekeeper/monkeypatch/docker'

describe Docker::Service, requires_docker: true do
  describe 'all services' do
    it 'can be listed' do
      services = Docker::Service.all.map(&:name)

      expect(services).to match_array(%w(
        beekeeper_cron
        beekeeper_cron_job_exits_nonzero
        beekeeper_cron_job_exits_zero
        beekeeper_cron_job_unscheduleable
        beekeeper_fail_fixed_labels
        beekeeper_fail_no_labels
      ))
    end

    it 'can be filtered by label' do
      services = Docker::Service.all({
        filters: {
          label: ['swarm.cronjob.enable=true']
        }
      }).map(&:name)

      expect(services).to match_array(%w(
        beekeeper_cron_job_exits_nonzero
        beekeeper_cron_job_exits_zero
        beekeeper_cron_job_unscheduleable
      ))
    end

    it 'can be filtered by name and label' do
      services = Docker::Service.all({
        filters: {
          name: ['beekeeper_cron_job_exits_'],
          label: ['swarm.cronjob.enable=true']
        }
      }).map(&:name)

      expect(services).to match_array(%w(
        beekeeper_cron_job_exits_nonzero
        beekeeper_cron_job_exits_zero
      ))
    end
  end

  describe 'a service' do
    context 'that succeeded' do
      subject(:service) { Docker::Service.get('beekeeper_cron_job_exits_zero') }

      it 'returns name' do
        expect(service.name).to eq 'beekeeper_cron_job_exits_zero'
      end

      it 'returns tasks' do
        tasks = service.tasks

        expect(tasks.size).to be > 0

        tasks.each do |task|
          expect(task.service_id).to eq service.id
          expect(task.image).to start_with 'alpine:latest'
          expect(%w(complete preparing running)).to include(task.state)
          expect(task.error).to be_nil
        end
      end

      it 'can be refreshed' do
        expect { service.refresh! }.not_to raise_error
      end
    end

    context 'that failed' do
      subject(:service) { Docker::Service.get('beekeeper_cron_job_exits_nonzero') }

      it 'returns name' do
        expect(service.name).to eq 'beekeeper_cron_job_exits_nonzero'
      end

      it 'returns tasks' do
        tasks = service.tasks
        expect(tasks.size).to be > 0

        tasks.each do |task|
          expect(task.service_id).to eq service.id
          expect(task.image).to start_with 'alpine:latest'
          expect(%w(failed preparing running)).to include(task.state)
          expect(task.error).to eq('task: non-zero exit (1)')
        end
      end
    end

    context 'that could not be scheduled' do
      subject(:service) { Docker::Service.get('beekeeper_cron_job_unscheduleable') }

      it 'returns name' do
        expect(service.name).to eq 'beekeeper_cron_job_unscheduleable'
      end

      it 'returns labels' do
        expect(service.label('beekeeper.watchers')).to eq '#some-channel,@some-user'
        expect(service.label('does-not-exist', 'foobar')).to eq 'foobar'
      end

      it 'returns tasks' do
        tasks = service.tasks

        expect(tasks.size).to be > 0

        tasks.each do |task|
          expect(task.service_id).to eq service.id
          expect(task.image).to eq 'alpine:this-tag-does-not-exist'
          expect(%w(preparing rejected)).to include(task.state)
          expect(task.error).to eq('No such image: alpine:this-tag-does-not-exist').or be_nil
        end
      end
    end
  end
end
