# Petit module encapsulates the Petit URL Shortener application
module Petit
  # Adds a configuration attribute to the Petit module.
  class << self
    attr_accessor :configuration
  end

  # Set configuration.
  #
  # Set the configuration attribute to itself or a new Configuration object if
  # it is currently nil. If a block is passed, evaluate it and assign the values.
  def self.configure
    self.configuration ||= Configuration.new
    yield(configuration) if block_given?
  end

  # Clear the configuration.
  def self.reset
    self.configuration = Configuration.new
  end

  # Configuration class for Petit.
  class Configuration
    attr_accessor :db_table_name, :not_found_destination, :api_base_url, :service_base_url, :require_ssl

    # Default configuration values
    def initialize
      @db_table_name = 'shortcodes'
      @not_found_destination = nil
      @api_base_url = 'http://localhost'
      @service_base_url = 'http://change.me'
      @require_ssl = true
    end
  end
end
