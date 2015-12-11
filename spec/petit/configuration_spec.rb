require "petit"
require "spec_helper"

module Petit
	describe Configuration do
		describe "#db_table_name" do
			it "default value is 'shortcodes'" do
				expect(Configuration.new.db_table_name).to eq('shortcodes')
			end
		end
		describe "#db_table_name=" do
			it "can set value" do
				config = Configuration.new
				config.db_table_name = 'smartcodes'
				expect(config.db_table_name).to eq('smartcodes')
			end
		end
		describe "#not_found_destination" do
			it "default value is nil" do
				expect(Configuration.new.not_found_destination).to be_nil
			end
		end
		describe "#not_found_destination=" do
			it "can set value" do
				config = Configuration.new
				config.not_found_destination = "http://www.404.org/"
				expect(config.not_found_destination).to eq("http://www.404.org/")
			end
		end
	end
end
