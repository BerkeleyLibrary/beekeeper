describe Beekeeper::Slack do
  let(:webhook_url) { 'https://hooks.slack.com/services/foo/bar/baz' }

  describe '#initialize' do
    it 'loads webhook URL from ENV["SLACK_WEBHOOK_URL"]' do
      stub_const('ENV', { 'SLACK_WEBHOOK_URL' => webhook_url })
      expect(subject.webhook_url).to eq webhook_url
    end

    it 'loads webhook URL from ENV["SLACK_WEBHOOK_URL_FILE"]' do
      stub_const('ENV', { 'SLACK_WEBHOOK_URL_FILE' => '/run/secrets/webhook_url' })
      expect(File).to receive(:exist?).with('/run/secrets/webhook_url').and_return true
      expect(File).to receive(:read).with('/run/secrets/webhook_url').and_return webhook_url
      expect(subject.webhook_url).to eq webhook_url
    end

    it 'loads webhook URL from /run/secrets/SLACK_WEBHOOK_URL' do
      stub_const('ENV', {})
      expect(File).to receive(:exist?).with('/run/secrets/SLACK_WEBHOOK_URL').and_return true
      expect(File).to receive(:read).with('/run/secrets/SLACK_WEBHOOK_URL').and_return webhook_url
      expect(subject.webhook_url).to eq webhook_url
    end

    it 'raises if not given a webhook URL' do
      stub_const('ENV', {})
      expect{ subject }.to raise_error /A webhook URL is required/
    end
  end
end
