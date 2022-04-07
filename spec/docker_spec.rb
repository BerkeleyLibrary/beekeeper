describe Beekeeper::Docker do
  describe '#container_logs' do
    it 'returns all logs by default' do
      logs = 'This is 29 characters of logs'
      expect(Excon).to receive(:get) { Excon::Response.new(body: logs) }
      expect(subject.container_logs(1)).to eq logs
    end

    it 'truncates logs' do
      logs = 'This is 29 characters of logs'
      expect(Excon).to receive(:get) { Excon::Response.new(body: logs) }
      expect(subject.container_logs(1, truncate: 10)).to eq 'rs of logs'
    end
  end
end
