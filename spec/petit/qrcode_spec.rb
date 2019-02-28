require 'petit'
require 'spec_helper'

module Petit
	describe QRcode do
  		describe '.generate' do
	    	it 'responds to generate' do
	    	  expect(Petit::QRcode).to respond_to(:generate)
	    	end
	    	it 'requires an argument' do
	    		expect{Petit::QRcode.generate}.to raise_error(ArgumentError)
	    	end 
	    	it 'returns a string' do
	     		expect(Petit::QRcode.generate("https://www.echocommunity.org")).to be_a String
	    	end
	    end
	end
end
