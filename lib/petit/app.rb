require "sinatra/base"
require "pp"
require "json"
require "pry"

module Petit
	class App < Sinatra::Application
		get '/' do
			redirect_to_not_found
		end	

		get '/:shortcode' do
			response = Shortcode.find_by_name(params[:shortcode])
			if response.nil?
				redirect_to_not_found
			else
				redirect_to(response)
			end
		end

		get '/api/v1/shortcodes.?:format?' do
			require_ssl params[:format]
			
			if params[:destination]
				shortcodes = Shortcode.find_by_destination(params[:destination])
				return_shortcode_collection(shortcodes, params[:format])
			else
				return_error 400, params[:format], "Must supply destination argument."
			end
		end

		get '/api/v1/shortcodes/:shortcode.?:format?' do
			shortcode = Shortcode.find_by_name(params[:shortcode])
			
			if shortcode.nil?
				return_not_found(params[:format])
			else
				return_shortcode(shortcode, params[:format])
			end
		end

		post '/api/v1/shortcodes.?:format?' do
			newShortcode = Shortcode.new("name" => params[:name], "destination" => params[:destination],"ssl" => params[:ssl])
			begin
				newShortcode.save
			rescue ShortcodeErrors::ShortcodeAccessError => e
				return_error 409, params[:format], e.message
			rescue ShortcodeErrors::IncompleteObjectError => e
				return_error 400, params[:format], e.message
			else
				headers 'Location' => Petit.configuration.api_base_url + '/api/v1/shortcodes/' + newShortcode.name
				shortcode = Shortcode.find_by_name(newShortcode.name)
				return_shortcode(shortcode, params[:format])
				return 201
			end
		end

		post '/api/v1/shortcodes/:shortcode.?:format?' do
			response = Shortcode.find_by_name(params[:shortcode])

			if response.nil?
				return_error 404, params[:format], "Records must be created on the collection."
			else
				return_error 409, params[:format], "Record Exists: Cannot modify record using POST, use PUT."
			end
		end

		put '/api/v1/shortcodes/:shortcode.?:format?' do
			shortcode = Shortcode.find_by_name(params[:shortcode])
			if shortcode.nil?
				return_error 404, params[:format], "Record does not exist."
			else
				shortcode.destination = params[:destination] || shortcode.destination
				shortcode.ssl = params[:ssl] || shortcode.ssl
				begin 
					shortcode.update
					return_shortcode(shortcode, params[:format])
				rescue ShortcodeErrors::IncompleteObjectError => e
					return_error 400, params[:format], e.message
				end
			end
		end

		delete '/api/v1/shortcodes/:shortcode.?:format?' do
			shortcode = Shortcode.find_by_name(params[:shortcode])
			if shortcode.nil?
				return_error 404, params[:format], "Record does not exist."
			else
				shortcode.destroy
				case params[:shortcode]
				when "json"
					response.headers['Content-Type'] = 'application/json'	
					"{}"
				else
					"Deleted"
				end
			end
		end

		def require_ssl(format = nil)
			unless request.secure?
				return_error 403, format, "HTTPS Required"
			end
		end

		def redirect_to(shortcode)
			url = ""
			if shortcode.ssl?
				url += "https://"
			else
				url += "http://"
			end
			url += shortcode.destination
			shortcode.hit
			redirect url, 301
		end

		def redirect_to_not_found
			if Petit.configuration.not_found_destination
				redirect Petit.configuration.not_found_destination, 303
			else
				return_not_found
			end
		end

		def return_not_found(format = nil)
			return_error(404, format, "Not Found")
		end

		def return_shortcode(shortcode, format = nil)
			case format
			when "json"
				response.headers['Content-Type'] = 'application/vnd.api+json'	
				JSONAPI::Serializer.serialize(shortcode).to_json
			else
				shortcode.name + " (" + shortcode.destination + ") "
			end
		end

		def return_shortcode_collection(shortcodes, format = nil)
			case format
			when "json"
				response.headers['Content-Type'] = 'application/vnd.api+json'
				JSONAPI::Serializer.serialize(shortcodes, is_collection: true).to_json
			else
				"No Plaintext Representation Exists"
			end
		end

		def return_error(error_code = 500, format=nil, message=nil, pointer=nil, parameter=nil)
			case format
			when "json"
				response.headers['Content-Type'] = 'application/vnd.api+json'
				jsonBody = {
					errors: [
						{
							status: error_code
						}
					]
				}

				jsonBody[:errors][0].store("message", message) if message
				if pointer
					jsonBody[:errors][0].store("source", {})
					jsonBody[:errors][0]['source'].store("pointer", pointer)
					jsonBody[:errors][0]['source'].store("parameter", parameter) if parameter
				end
				halt error_code, jsonBody.to_json
			else
				halt error_code, message
			end
		end
	end
end