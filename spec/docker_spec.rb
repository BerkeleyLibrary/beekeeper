require 'beekeeper/monkeypatch/docker'

describe Docker::Service, requires_docker: true do
  TESTING_SERVICE = 'beekeeper_fail_fixed_labels'

  subject { Docker::Service.get(TESTING_SERVICE) }

  it 'gets an existing service' do
    expect(subject.info['Spec']['Name']).to eq TESTING_SERVICE
  end

  describe '#service_label' do
    it 'returns a specific label' do
      expect(subject.service_label('beekeeper.watchers')).to eq '#some-channel,@some-user'
    end

    it 'returns a default value if not found' do
      expect(subject.service_label('does-not-exist', 'foobar')).to eq 'foobar'
    end
  end
end
