require "spec_helper"
require "petit"

describe Petit do
	it "has default configuration values" do
		expect(Petit.configuration.db_table_name).to eq('shortcodes')
	end

	describe "#configure" do
		before do
			Petit.configure do | config |
				config.db_table_name = 'shortcodess'
			end
		end

		it "reads the configuration" do
	      expect(Petit.configuration.db_table_name).to eq('shortcodess')
	    end
	end
end