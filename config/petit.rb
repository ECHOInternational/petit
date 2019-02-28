# Set configuration values using these environment variables.
Petit.configure do |config|
  config.db_table_name = ENV['DB_TABLE_NAME'] # || 'shortcodes'
  config.api_base_url = ENV['API_BASE_URL'] # || 'http://localhost:3000'
  config.service_base_url = ENV['SERVICE_BASE_URL'] # || 'http://change.me'
  config.not_found_destination = ENV['NOT_FOUND_DESTINATION'] # || 'http://www.google.com'
  config.require_ssl = ENV['REQUIRE_SSL'] === 'false' ? false : true  # || true
end
