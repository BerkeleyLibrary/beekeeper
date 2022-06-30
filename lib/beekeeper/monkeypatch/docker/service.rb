require 'docker'

class Docker::Service
  include Docker::Base

  class << self
    def get(id_or_name, opts = {}, conn = Docker.connection)
      new(conn, { 'ID' => id_or_name }).refresh!
    end
  end

  def service_label(label, default_value = nil)
    service_labels.fetch(label, default_value)
  end

  def service_labels
    info['Spec'].fetch('Labels', {})
  end

  def refresh!
    self.tap do |service|
      resp = @connection.get(api_path)
      service.info = Docker::Util.parse_json(resp)
    end
  end

  private

  def api_path(action = nil)
    action.nil? ? "/services/#{self.id}" : "/services/#{self.id}/#{action}"
  end
end
