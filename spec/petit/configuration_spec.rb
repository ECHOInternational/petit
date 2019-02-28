require 'petit'
require 'spec_helper'

module Petit
  describe Configuration do
    describe '#db_table_name' do
      it "default value is 'shortcodes'" do
        expect(Configuration.new.db_table_name).to eq('shortcodes')
      end
    end
    describe '#db_table_name=' do
      it 'can set value' do
        config = Configuration.new
        config.db_table_name = 'smartcodes'
        expect(config.db_table_name).to eq('smartcodes')
      end
    end
    describe '#not_found_destination' do
      it 'default value is nil' do
        expect(Configuration.new.not_found_destination).to be_nil
      end
    end
    describe '#not_found_destination=' do
      it 'can set value' do
        config = Configuration.new
        config.not_found_destination = 'http://www.404.org/'
        expect(config.not_found_destination).to eq('http://www.404.org/')
      end
    end
    describe '#api_base_url' do
      it "default value is 'http://localhost'" do
        expect(Configuration.new.api_base_url).to eq('http://localhost')
      end
    end
    describe '#api_base_url=' do
      it 'can set value' do
        config = Configuration.new
        config.api_base_url = 'https://api.link.me'
        expect(config.api_base_url).to eq('https://api.link.me')
      end
    end
    describe '#require_ssl' do
      it "default value is true" do
        expect(Configuration.new.require_ssl).to be true
      end
    end
    describe '#require_ssl=' do
      it 'can set value' do
        config = Configuration.new
        config.require_ssl = false
        expect(config.require_ssl).to be false
      end
    end
    describe '#service_base_url' do
      it "default value is 'http://change.me'" do
        expect(Configuration.new.service_base_url).to eq('http://change.me')
      end
    end
    describe '#service_base_url=' do
      it 'can set value' do
        config = Configuration.new
        config.service_base_url = 'http://link.me'
        expect(config.service_base_url).to eq('http://link.me')
      end
    end
  end
end
