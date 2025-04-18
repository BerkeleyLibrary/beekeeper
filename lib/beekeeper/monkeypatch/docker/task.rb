require 'docker'

class Docker::Task
  include Docker::Base

  class << self
    def all(opts = {}, conn = Docker.connection)
      opts[:filters] ||= {}
      opts[:filters] = opts[:filters].to_json
      Docker::Util.parse_json(conn.get(path_for, opts)).map { |info| new(conn, info) }
    end

    private

    def base_path
      'tasks'
    end

    def path_for(id = nil)
      id.nil? ? base_path : "#{base_path}/#{id}"
    end
  end

  def error
    info['Status']['Err']
  end

  def image
    info['Spec']['ContainerSpec']['Image']
  end

  def service_id
    info['ServiceID']
  end

  def refresh!
    self.tap do
      @info = Docker::Util.parse_json(@connection.get(path_for)).first
    end
  end

  def state
    info['Status']['State']
  end

  %w(complete failed preparing rejected running).each do |status|
    define_method("#{status}?".to_sym) { state == status }
  end

  def to_s
    "Docker::Task { :id => #{self.id}, :connection => #{self.connection} }"
  end

  private

  def path_for
    self.class.send(:path_for, id)
  end
end
