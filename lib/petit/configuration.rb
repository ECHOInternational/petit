module Petit
  class << self
    attr_accessor :configuration
  end

  def self.configure
    self.configuration ||= Configuration.new
    yield(configuration) if block_given?
  end

  def self.reset
    self.configuration = Configuration.new
  end

  class Configuration
    attr_accessor :db_table_name, :not_found_destination, :api_base_url, :service_base_url

    def initialize
      @db_table_name = 'shortcodes'
      @not_found_destination = nil
      @api_base_url = "http://localhost"
      @service_base_url = "http://change.me"
    end
  end
end