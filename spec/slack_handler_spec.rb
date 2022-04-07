describe Beekeeper::SlackHandler do
  subject { Beekeeper::SlackHandler.new(connection: connection, docker: docker) }
  let(:connection) { instance_double(Excon::Connection) }
  let(:docker) { instance_double(Beekeeper::Docker) }

  before :each do
    expect(connection).to receive(:data) { {headers: {}} }
  end

  describe '#handle' do
    it 'notifies on service failure events' do
      expect(connection).to receive(:post)
      expect(docker).to receive(:container_logs)
        .with('615e666450d86dfed3d2fe07f6192e6d8772062cc237f820511acd52f6a4629c', truncate: 5000)
        .and_return('some logs')

      event = Beekeeper::Event.new(fixture('service_failure_event.json').read)
      subject.handle(event)
    end

    it 'ignores non-service failure events' do
      expect(connection).not_to receive(:post)

      event = Beekeeper::Event.new(fixture('disconnect_event.json').read)
      subject.handle(event)
    end
  end
end
