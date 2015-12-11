Petit.configure do |config|
	config.db_table_name = 'shortcodes'
    config.not_found_destination = 'http://www.google.com'
end