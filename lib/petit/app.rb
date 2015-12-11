require "sinatra/base"
require "pp"

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

		def redirect_to(shortcode)
			url = ""
			if shortcode.ssl?
				url += "https://"
			else
				url += "http://"
			end
			url += shortcode.destination

			if params[:debug]
				"#{url} (#{shortcode.name})"
			else
				shortcode.hit
				redirect url, 301
			end
		end

		def redirect_to_not_found
			if Petit.configuration.not_found_destination
				redirect Petit.configuration.not_found_destination, 303
			else
				status 404
				"Not Found"
			end
		end
	end
end