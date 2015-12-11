require 'petit'
require 'spec_helper'
require 'rack/test'
require 'pry'

describe 'Petit App' do
  include Rack::Test::Methods

  def app
    Petit::App
  end

	Petit.configure

  after(:each) do
  	Petit.reset
  end

  describe "get '/'" do
	  context "when no not_found_destination is defined" do
	  	it "a not_found_destination is nil" do
				expect(Petit.configuration.not_found_destination).to be_nil
			end
		  it "throws 404 from root" do
		    get '/'
		    expect(last_response).to be_not_found
		  end
		end

		context "when a not_found_destination is defined" do

			it "has a not_found_destination configured" do
				Petit.configuration.not_found_destination  = 'http://www.google.com/'
				expect(Petit.configuration.not_found_destination).to_not be_nil
			end
			it "redirects to defined 404 page from root" do
				Petit.configuration.not_found_destination  = 'http://www.google.com/'
				get '/'
				expect(last_response).to be_redirect
				follow_redirect!
				expect(last_request.url).to eql 'http://www.google.com/'
			end
		end
	end

	describe "get ':/shortcode'" do
		
		context "when the shortcode is found" do

			context "when it is not in debug mode" do
				it "redirects to the correct destination" do
					get '/abc123'
					expect(last_response).to be_redirect
					follow_redirect!
					expect(last_request.url).to eq('http://www.yahoo.com/')
				end

				it "increments the access_count" do
					shortcode_pre = Shortcode.find('abc123')
					get 'abc123'
					shortcode_post = Shortcode.find('abc123')
					expect(shortcode_post.access_count).to eq(shortcode_pre.access_count + 1)
				end

			end

			context "when it is in debug mode" do
				it "returns the destination and interpreted short code as text" do
					get 'abc123?debug=true'
					expect(last_response).to be_ok
					expect(last_response.body).to eq('http://www.yahoo.com (abc123)')
				end
				it "downcases the shortcode" do
					get '/ABC123?debug=true'
					expect(last_response.body).to eq('http://www.yahoo.com (abc123)')
				end
				it "does not increment the access_count" do
					shortcode_pre = Shortcode.find('abc123')
					get 'abc123?debug=true'
					shortcode_post = Shortcode.find('abc123')
					expect(shortcode_post.access_count).to eq(shortcode_pre.access_count)
				end

			end

		end

		context "when the shortcode is not found" do
			context "when no not_found_destination is defined" do
		  	it "a not_found_destination is nil" do
					expect(Petit.configuration.not_found_destination).to be_nil
				end
			  it "throws 404 from root" do
			    get '/ajdslfjasoidhajldsnfasd'
			    expect(last_response).to be_not_found
			  end
			end

			context "when a not_found_destination is defined" do

				it "has a not_found_destination configured" do
					Petit.configuration.not_found_destination  = 'http://www.google.com/'
					expect(Petit.configuration.not_found_destination).to_not be_nil
				end
				it "redirects to defined 404 page from root" do
					Petit.configuration.not_found_destination  = 'http://www.google.com/'
					get '/ajdslfjasoidhajldsnfasd'
					expect(last_response).to be_redirect
					follow_redirect!
					expect(last_request.url).to eql 'http://www.google.com/'
				end
			end
		end
	end

end