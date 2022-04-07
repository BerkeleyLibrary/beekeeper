describe Beekeeper::Watcher do
  subject { Beekeeper::Watcher.new(docker: docker, handler: handler) }
  let(:docker) { instance_double(Beekeeper::Docker) }
  let(:handler) { instance_double(Beekeeper::SlackHandler) }

  describe '#watch!' do
    it 'swallows handler errors' do
      expect(docker).to receive(:events).and_yield('Event')
      expect(handler).to receive(:handle) { raise 'An error occurred' }

      subject.watch!
    end

    it 'dies on docker events errors' do
      expect(docker).to receive(:events) { raise 'An error occurred' }

      expect { subject.watch! }.to raise_error
    end
  end
end
