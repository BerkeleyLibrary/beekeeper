describe Beekeeper::Event do
  subject { Beekeeper::Event.new(fixture('service_failure_event.json').read) }

  describe '#simplified_image_name' do
    it 'strips the leading registry name' do
      expect(subject.simplified_image_name).to eq('.../lap/ruby:3.0.3-slim')
    end
  end
end
