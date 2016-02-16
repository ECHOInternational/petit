require 'petit'
require 'spec_helper'
require 'rack/test'
require 'rack/parser'
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

	describe "get '/api/v1/shortcodes'" do
		context "when ssl is not employed" do
			it "returns error type 403 'HTTPS Required'" do
				get '/api/v1/shortcodes'
				expect(last_response.status).to eq 403
			end
		end
		context "when json is requested" do
			it "returns Content-Type of 'application/vnd.api+json'" do
				header 'Accept', 'application/json'
				get '/api/v1/shortcodes', {"destination" => "www.gobbledygoodadfadf.id"}, {'HTTPS' => 'on'}
				expect(last_response.header['Content-Type']).to include 'application/vnd.api+json'
			end
			it "returns a json object" do
				header 'Accept', 'application/json'
				get '/api/v1/shortcodes', params={"destination" => "www.gobbledygoodadfadf.id"}, {'HTTPS' => 'on'}
				expect {
					JSON.parse(last_response.body)
				}.to_not raise_error
			end
		end
		context "when destination argument is not supplied" do
			it "returns an error code 400" do
				get '/api/v1/shortcodes', {}, {'HTTPS' => 'on'}
				expect(last_response.status).to eq 400
			end
			context "when json is requested" do
				it "returns a json api conformant object" do
					header 'Accept', 'application/json' 
					get '/api/v1/shortcodes', {}, {'HTTPS' => 'on'}
					json_response = JSON.parse(last_response.body)
					expect(json_response).to include "errors"
					expect(json_response['errors']).to be_a Array
					expect(json_response['errors'].length).to be >= 1
					expect(json_response['errors'][0]).to include "message"
				end
			end
		end
		context "when destination argument is supplied" do
			context "when json is requested" do
				it "returns a jsonapi conformant object" do
					header 'Accept', 'application/json'
					get '/api/v1/shortcodes', params={"destination" => "www.gobbledygoodadfadf.id"}, {'HTTPS' => 'on'}
					json_response = JSON.parse(last_response.body)
					expect(json_response).to include "data"
				end
				context "when no records exist" do
					it "returns and empty array" do
						header 'Accept', 'application/json'
						get '/api/v1/shortcodes', params={"destination" => "www.gobbledygoodadfadf.id"}, {'HTTPS' => 'on'}
						json_response = JSON.parse(last_response.body)
						expect(json_response['data']).to eq []
					end
				end
				context "when records exist" do
					it "returns and array of hashes" do
						header 'Accept', 'application/json'
						get '/api/v1/shortcodes', params={"destination" => "www.yahoo.com"}, {'HTTPS' => 'on'}
						json_response = JSON.parse(last_response.body)
						expect(json_response['data']).to be_kind_of Array
						expect(json_response['data'].length).to be > 0 
					end
					it "returns child objects with destination and interpreted short code as json" do
						header 'Accept', 'application/json'
						get '/api/v1/shortcodes', params={"destination" => "www.yahoo.com"}, {'HTTPS' => 'on'}
						json_response = JSON.parse(last_response.body)
						expect(json_response['data'][0]['attributes']).to include "name"
						expect(json_response['data'][0]['attributes']).to include "destination"
					end
					it "returns child objects with a url to the generated shortcode" do
						header 'Accept', 'application/json'
						get '/api/v1/shortcodes', params={"destination" => "www.yahoo.com"}, {'HTTPS' => 'on'}
						json_response = JSON.parse(last_response.body)
						expect(json_response['data'][0]['meta']).to include "generated_link"
						expect(json_response['data'][0]['meta']['generated_link']).to be_kind_of String
					end
				end
			end
		end
	end

	describe "get '/api/v1/shortcodes/:shortcode'" do
		context "when ssl is not employed" do
			it "returns error type 403 'HTTPS Required'" do
				get '/api/v1/shortcodes/abc123'
				expect(last_response.status).to eq 403
			end
		end
		context "when json is requested" do
			context "when the shortcode is present" do
				it "returns Content-Type of 'application/vnd.api+json'" do
					get '/api/v1/shortcodes/abc123', {'HTTPS' => 'on'}
					expect(last_response.header['Content-Type']).to include 'application/vnd.api+json'
				end
				it "returns a json object" do
					get '/api/v1/shortcodes/abc123', {'HTTPS' => 'on'}
					expect {
						JSON.parse(last_response.body)
					}.to_not raise_error
				end
				it "returns a jsonapi conformant object" do
					header 'Accept', 'application/json'
					get '/api/v1/shortcodes/abc123', {}, {'HTTPS' => 'on'}
					json_response = JSON.parse(last_response.body)
					expect(json_response).to include "data"
					expect(json_response['data']).to include "attributes"
				end
				it "returns the destination and interpreted short code as json" do
					get '/api/v1/shortcodes/abc123', {}, {'HTTPS' => 'on'}
					json_response = JSON.parse(last_response.body)
					expect(json_response['data']['attributes']).to include "name"
					expect(json_response['data']['attributes']).to include "destination"
				end
				it "returns a url to the generated shortcode" do
					get '/api/v1/shortcodes/abc123', {}, {'HTTPS' => 'on'}
					json_response = JSON.parse(last_response.body)
					expect(json_response['data']['meta']).to include "generated_link"
					expect(json_response['data']['meta']['generated_link']).to eq Petit.configuration.service_base_url + "/abc123"
				end
				it "downcases the shortcode" do
					get '/api/v1/shortcodes/ABC123', {}, {'HTTPS' => 'on'}
					json_response = JSON.parse(last_response.body)
					expect(json_response['data']['attributes']['name']).to eq('abc123')
				end
				it "does not increment the access_count" do
					shortcode_pre = Shortcode.find('abc123')
					get '/api/v1/shortcodes/abc123', {}, {'HTTPS' => 'on'}
					shortcode_post = Shortcode.find('abc123')
					expect(shortcode_post.access_count).to eq(shortcode_pre.access_count)
				end
			end
			context "when the shortcode is not present" do
				it "returns an 404 (not found) error" do
					get '/api/v1/shortcodes/thisisnotfoundever.json', {}, {'HTTPS' => 'on'}
					expect(last_response).to be_not_found
				end
				it "returns a JSON object" do
					get '/api/v1/shortcodes/thisisnotfoundever.json', {}, {'HTTPS' => 'on'}
					expect {
						JSON.parse(last_response.body)
					}.to_not raise_error
				end
				it "returns a JSON error message" do
					get '/api/v1/shortcodes/thisisnotfoundever.json', {}, {'HTTPS' => 'on'}
					json_response = JSON.parse(last_response.body)
					expect(json_response).to include "errors"
					expect(json_response['errors']).to be_a Array
					expect(json_response['errors'].length).to be >= 1
					expect(json_response['errors'][0]).to include "message"
				end
			end
		end
	end

	describe "post '/api/v1/shortcodes'" do
		context "when ssl is not employed" do
			it "returns error type 403 'HTTPS Required'" do
				post '/api/v1/shortcodes', params={"name" => "testcode", "destination" => "www.testcode.io", "ssl" => true}
				expect(last_response.status).to eq 403
			end
		end
		context "when arguments are supplied as json" do
			before(:context) do
				shortcode = Shortcode.find('testcodejson')
				if shortcode
					shortcode.destroy
				end
			end
			it "parses the json and creates the record" do
				jsonBody = {
					data: {
						type: "shortcodes",
						attributes: {
							name: "testcodejson",
							destination: "www.testcodejson.io",
							ssl: true
						}
					}
				}
				header 'Content-type', 'application/vnd.api+json'
				header 'Accept', 'application/vnd.api+json'
				post '/api/v1/shortcodes', jsonBody.to_json, {'HTTPS' => 'on'}
				expect(last_response.status).to eq 201
				found = Shortcode.find('testcodejson')
				expect(found).to_not be_nil
				expect(found.name).to eq 'testcodejson'
				expect(found.destination).to eq 'www.testcodejson.io'
				expect(found.ssl?).to be true
			end
		end
		context "when shortcode does not already exist" do
			before(:context) do 
				shortcode = Shortcode.find('testcode')
				if shortcode 
					shortcode.destroy
				end
			end
			context "when parameters are correct" do 
				it "returns 201 (created)" do 	
					post '/api/v1/shortcodes', params={"name" => "testcode", "destination" => "www.testcode.io", "ssl" => true}, {'HTTPS' => 'on'}
					expect(last_response.status).to eq 201
				end
				it "creates a shortcode" do
					found = Shortcode.find('testcode')
					expect(found).to_not be_nil
				end
				it "has correct values" do
					found = Shortcode.find('testcode')
					expect(found.name).to eq 'testcode'
					expect(found.destination).to eq 'www.testcode.io'
					expect(found.ssl?).to be true
				end
				it "returns a Location header with a link to the new address" do
					shortcode = Shortcode.find('testcode')
					if shortcode 
						shortcode.destroy
					end
					post '/api/v1/shortcodes', params={"name" => "testcode", "destination" => "www.testcode.io", "ssl" => true}, {'HTTPS' => 'on'}
					expect(last_response.headers).to include "Location"
					expect(last_response.headers["Location"]).to eq Petit.configuration.api_base_url + "/api/v1/shortcodes/testcode"
				end
			end
			context "when parameters are not correct" do
				it "returns 400 (Bad Request)" do
					post '/api/v1/shortcodes', params={"name" => "testcode"}, {'HTTPS' => 'on'}
					expect(last_response.status).to eq 400
				end
			end
		end
		context "when shortcode already exists" do
			it "throws a 409 (conflict) error" do
				get '/testshortcodeunsuccessful'
				expect(last_response).to be_redirect
				follow_redirect!
				expect(last_request.url).to eq('https://www.test.me/')
				post '/api/v1/shortcodes', params={"name" => "testshortcodeunsuccessful", "destination" => "www.test.me", "ssl" => true}, {'HTTPS' => 'on'}
				expect(last_response.status).to eq 409
			end
		end
	end

	describe "put '/'" do
		context "when no not_found_destination is defined" do
	  		it "a not_found_destination is nil" do
				expect(Petit.configuration.not_found_destination).to be_nil
			end
			it "throws 404 from root" do
				put '/'
				expect(last_response).to be_not_found
			end
		end

		context "when a not_found_destination is defined" do

			it "has a not_found_destination configured" do
				Petit.configuration.not_found_destination  = 'http://www.google.com/'
				expect(Petit.configuration.not_found_destination).to_not be_nil
			end
			it "throws 404 from root" do
				Petit.configuration.not_found_destination  = 'http://www.google.com/'
				put '/'
				expect(last_response).to be_not_found
			end
		end
	end

	describe "delete '/'" do
		context "when no not_found_destination is defined" do
	  		it "a not_found_destination is nil" do
				expect(Petit.configuration.not_found_destination).to be_nil
			end
			it "throws 404 from root" do
				delete '/'
				expect(last_response).to be_not_found
			end
		end

		context "when a not_found_destination is defined" do

			it "has a not_found_destination configured" do
				Petit.configuration.not_found_destination  = 'http://www.google.com/'
				expect(Petit.configuration.not_found_destination).to_not be_nil
			end
			it "throws 404 from root" do
				Petit.configuration.not_found_destination  = 'http://www.google.com/'
				delete '/'
				expect(last_response).to be_not_found
			end
		end
	end

	describe "put '/api/v1/shortcodes/:shortcode'" do
		context "when ssl is not employed" do
			it "returns error type 403 'HTTPS Required'" do
				put '/api/v1/shortcodes/notthere23480238', params={"name" => "nocreate", "destination" => "www.shouldntwork.com"}
				expect(last_response.status).to eq 403
			end
		end
		context "if the shortcode is not found" do
			it "throws a 404 (not found) error" do
				put '/api/v1/shortcodes/notthere23480238', params={"name" => "nocreate", "destination" => "www.shouldntwork.com", "ssl" => false}, {'HTTPS' => 'on'}
				expect(last_response).to be_not_found
			end
			context "when json is requested" do
				it "returns a json api conformant object" do
					put '/api/v1/shortcodes/notthere23480238.json', params={"name" => "nocreate", "destination" => "www.shouldntwork.com", "ssl" => false}, {'HTTPS' => 'on'}	
					json_response = JSON.parse(last_response.body)
					expect(json_response).to include "errors"
					expect(json_response['errors']).to be_a Array
					expect(json_response['errors'].length).to be >= 1
					expect(json_response['errors'][0]).to include "message"
				end
			end
		end
		context "if the shortcode is found" do
			context "if the updated data is valid" do
				
				shortcode = Shortcode.new({name: 'abc124', destination: 'www.yahoo.com', ssl: true})
				shortcode.destroy
				shortcode.save

				it "returns 200" do
					put '/api/v1/shortcodes/abc124', params={"destination" => "www.google.com"}, {'HTTPS' => 'on'}
					expect(last_response).to be_ok
				end
				it "updates the destination" do
					put '/api/v1/shortcodes/abc124', params={"destination" => "www.foogle.com"}, {'HTTPS' => 'on'}
					expect(last_response).to be_ok
					result = Shortcode.find_by_name('abc124')
					expect(result.destination).to eq "www.foogle.com"
				end
				it "does not override parameters that are not passed" do
					result = Shortcode.find_by_name('abc124')
					expect(result.ssl?).to be true
				end
				it "updates the ssl flag" do
					put '/api/v1/shortcodes/abc124', params={"ssl" => false}, {'HTTPS' => 'on'}
					expect(last_response).to be_ok
					result = Shortcode.find_by_name('abc124')
					expect(result.ssl?).to be false
				end
				it "ignores an attempt to update the name" do
					put '/api/v1/shortcodes/abc124', params={"name" => "newnamethatdoesntexist"}, {'HTTPS' => 'on'}
					expect(last_response).to be_ok
					result = Shortcode.find_by_name('newnamethatdoesntexist')
					expect(result).to be_nil
					result = Shortcode.find_by_name('abc124')
					expect(result.name).to eq "abc124"
				end
				context "when arguments are supplied as json" do
					it "parses the json and updates the record" do
						jsonBody = {
							data: {
								type: "shortcodes",
								attributes: {
									name: "abc125",
									destination: "www.moogle.com",
									ssl: true
								}
							}
						}
						header 'Content-type', 'application/vnd.api+json'
						header 'Accept', 'application/vnd.api+json'
						put '/api/v1/shortcodes/abc124', jsonBody.to_json, {'HTTPS' => 'on'}
						expect(last_response.status).to eq 200
						found = Shortcode.find('abc124')
						expect(found).to_not be_nil
						expect(found.name).to eq 'abc124' #It shouldn't be able to change the name
						expect(found.destination).to eq 'www.moogle.com'
						expect(found.ssl?).to be true
					end
				end			
			end
			context "if the updated data is invalid" do
				shortcode = Shortcode.new({name: 'abc124', destination: 'www.yahoo.com', ssl: true})
				shortcode.destroy
				shortcode.save
				
				it "throws a 400 (Bad Request) error" do
					put '/api/v1/shortcodes/abc124', params={"destination"=>""}, {'HTTPS' => 'on'}
					expect(last_response.status).to eq 400
				end

			end
		end
	end

	describe "delete '/api/v1/shortcodes/:shortcode'" do
		context "when ssl is not employed" do
			it "returns error type 403 'HTTPS Required'" do
				delete '/api/v1/shortcodes/notthere23480238'
				expect(last_response.status).to eq 403
			end
		end
		context "if the shortcode is not found" do
			it "throws a 404 (not found) error" do
				delete '/api/v1/shortcodes/notthere23480238', {},  {'HTTPS' => 'on'}
				expect(last_response).to be_not_found
			end
		end
		context "if the shortcode is found" do
			it "deletes the record" do
				shortcode = Shortcode.new({name: 'abc124', destination: 'www.yahoo.com', ssl: true})
				shortcode.destroy
				shortcode.save
				
				get '/abc124'
				expect(last_response).to be_redirect

				delete '/api/v1/shortcodes/abc124', {}, {'HTTPS' => 'on'}
				
				get '/abc124'
				expect(last_response).to be_not_found

			end
			it "returns 200" do
				shortcode = Shortcode.new({name: 'abc124', destination: 'www.yahoo.com', ssl: true})
				shortcode.destroy
				shortcode.save

				delete '/api/v1/shortcodes/abc124',{}, {'HTTPS' => 'on'}
				expect(last_response).to be_ok
			end
		end
	end
end