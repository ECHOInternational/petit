require 'sinatra/base'
require 'rack/parser'
require_relative 'jsonapiparser'

module Petit
  # Sinatra application class to serve HTTP API requests
  #   All requests can be made as 'text/html' with parameters as form values, or as JSONAPI objects
  #   To communicate with the API using JSON, set ACCEPTS header to 'application/vnd.api+json'
  # rubocop:disable Metrics/ClassLength
  class App < Sinatra::Application
    use Rack::Parser, parsers: {
      'application/vnd.api+json' => JSONapiParser.new
    }
    # use Rack::Parser, parsers: {
    #   'application/vnd.api+json' => proc { |data|
    #     JSON.parse(data).dig('data', 'attributes')
    #   }
    # }

    # @method get_root
    # @overload get '/'
    # Gets the root url with no shortcode, always returns (404) Not Found
    get '/' do
      redirect_to_not_found
    end

    # @method get_shortcode
    # @overload get '/:shortcode'
    # @param shortcode [String] the shortcode to which to redirect
    # Finds the provided shortcode and redirects to it's destination.
    # If the provided shortcode is not found it redirects to (404) Not Found
    get '/:shortcode' do
      response = Petit::Shortcode.find_by_name(params[:shortcode])
      if response.nil?
        redirect_to_not_found
      else
        redirect_to(response)
      end
    end

    # @method api_get_shortcode_by_destination
    # @overload get '/api/v1/shortcodes'
    # @param destination [String] the destination url to find in the database
    # Finds and returns zero or more shortcode objects based on their destination.
    # Parameters can either be submitted as form values or in the body as JSONAPI objects
    get '/api/v1/shortcodes' do
      require_ssl
      if params[:destination]
        shortcodes = Petit::Shortcode.find_by_destination(params[:destination])
        return_shortcode_collection(shortcodes)
      else
        return_error(error_code: 400, message: 'Must supply destination argument.')
      end
    end

    # @method api_get_suggestion
    # @overload get '/api/v1/suggestion'
    # Returns a random shortcode name that is not currently in use in the system.
    # @todo add parameter to specify length.
    get '/api/v1/suggestion' do
      require_ssl
      return_suggestion
    end

    # @method api_head_shortcode
    # @overload head 'api/v1/shortcodes/:shortcode'
    # @param shortcode [String] the shortcode to find in the database
    # Returns 200 if found 404 if not
    head '/api/v1/shortcodes/:shortcode' do
      require_ssl

      shortcode = Petit::Shortcode.find_by_name(params[:shortcode])

      if shortcode.nil?
        404
      else
        200
      end
    end

    # @method api_get_shortcode
    # @overload get '/api/v1/shortcodes/:shortcode'
    # @param shortcode [String] the shortcode to find in the database
    # Finds and returns a single shortcode object by its name.
    # If no shortcode is found by that name a 404 (Not Found) response is issued
    get '/api/v1/shortcodes/:shortcode' do
      require_ssl

      shortcode = Petit::Shortcode.find_by_name(params[:shortcode])

      if shortcode.nil?
        return_not_found
      else
        return_shortcode(shortcode)
      end
    end

    # @method api_create_shortcode
    # @overload post '/api/v1/shortcodes'
    # @param name [String] the name of the shortcode
    # @param destination [String] the destination URL for the shortcode (do not include protocol)
    # @param ssl [String] the protocol to use for the shortcode (true for https, false for http)
    # Creates a new shortcode.
    # Returns 201 with Location header for the newly created resource on sucess
    # Returns 4XX with error message on failure
    post '/api/v1/shortcodes' do
      require_ssl
      new_shortcode = Petit::Shortcode.new(
        'name' => params[:name],
        'destination' => params[:destination],
        'ssl' => params[:ssl]
      )
      begin
        new_shortcode.save
      rescue Petit::ShortcodeAccessError => e
        return_error(error_code: 409, message: e.message)
      rescue Petit::IncompleteObjectError => e
        return_error(error_code: 400, message: e.message)
      else
        headers(
          'Location' =>
            Petit.configuration.api_base_url +
            '/api/v1/shortcodes/' +
            new_shortcode.name
        )
        shortcode = Petit::Shortcode.find_by_name(new_shortcode.name)
        return 201, return_shortcode(shortcode)
      end
    end

    # @method api_create_existing_shortcode
    # @overload post '/api/v1/shortcodes/:shortcode'
    # This method always returns an error as shortcodes cannot be overwritten.
    # To update a shortcode use "put '/api/v1/shortcodes/:shortcode'". See {#api_update_shortcode}
    post '/api/v1/shortcodes/:shortcode' do
      require_ssl

      response = Petit::Shortcode.find_by_name(params[:shortcode])
      if response.nil?
        return_error(
          error_code: 404,
          message: 'Records must be created on the collection.'
        )
      else
        return_error(
          error_code: 409,
          message: 'Record Exists: Cannot modify record using POST, use PUT.'
        )
      end
    end

    # @method api_update_shortcode
    # @overload put '/api/v1/shortcodes/:shortcode'
    # @param shortcode [String] the shortcode to update (should be provided in URL)
    # @param destination [String] (Optional) the destination URL for the shortcode
    #  (do not include protocol)
    # @param ssl [String] (Optional) the protocol to use for the shortcode
    #  (true for https, false for http)
    # Updates an existing shortcode.
    # On success a 200 response is returned along with the updated Shortcode object parameters
    # If shortcode specified does not exist a 404 error is returned
    # If parameter values do not pass validation a 400 error is returned
    put '/api/v1/shortcodes/:shortcode' do
      require_ssl
      # if request.content_type == "application/vnd.api+json"
      #   binding.pry
      # end
      shortcode = Petit::Shortcode.find_by_name(params[:shortcode])
      if shortcode.nil?
        return_error(error_code: 404, message: 'Record does not exist.')
      else
        shortcode.destination = params[:destination] || shortcode.destination
        shortcode.ssl = params[:ssl] || shortcode.ssl
        begin
          shortcode.update
          return_shortcode(shortcode)
        rescue Petit::IncompleteObjectError => e
          return_error(error_code: 400, message: e.message)
        end
      end
    end

    # @method api_delete_shortcode
    # @overload delete '/api/v1/shortcodes/:shortcode'
    # @param shortcode [String] the shortcode to delete
    # Deletes a shortcode
    delete '/api/v1/shortcodes/:shortcode' do
      require_ssl
      shortcode = Petit::Shortcode.find_by_name(params[:shortcode])
      if shortcode.nil?
        return_error(error_code: 404, message: 'Record does not exist.')
      else
        shortcode.destroy
        if request.accept?('application/json') || request.accept?('application/vnd.api+json')
          response.headers['Content-Type'] = 'application/vnd.api+json'
          '{}'
        else
          'Deleted'
        end
      end
    end

    # Guard method that returns a 403 'HTTPS Required' error when SSL is not employed
    def require_ssl
      return unless Petit.configuration.require_ssl
      return_error(error_code: 403, message: 'HTTPS Required') unless request.secure?
    end

    # 301 Redirects requests to the shortcode destination.
    # Note: this method increments the shortcode's hit counter
    # @param shortcode [Shortcode] the shortcode object from which to build the redirect URL
    def redirect_to(shortcode)
      url = ''
      url += if shortcode.ssl?
               'https://'
             else
               'http://'
             end
      url += shortcode.destination
      shortcode.hit
      redirect url, 301
    end

    # 303 Redirects to a not_found_destination from the configuration, or
    # returns 404 'Not Found' if not not_found_destination is specified
    def redirect_to_not_found
      if Petit.configuration.not_found_destination
        redirect Petit.configuration.not_found_destination, 303
      else
        return_not_found
      end
    end

    # Always returns 404 'Not Found'
    def return_not_found
      return_error(error_code: 404, message: 'Not Found')
    end

    # Gets a suggested name for a shortcode
    # @return [String] the suggested shortcode name
    def return_suggestion
      suggestion = Petit::Shortcode.suggest
      if request.accept?('application/json') || request.accept?('application/vnd.api+json')
        response.headers['Content-Type'] = 'application/vnd.api+json'
        json_body = {
          data: {
            type: 'suggestion',
            id: suggestion,
            attributes: {
              name: suggestion
            }
          }
        }
        json_body.to_json
      else
        suggestion
      end
    end

    # Returns a formatted representation of a given shortcode object
    # @param shortcode [Shortcode] the shortcode object to format
    # @return [String] a JSON representation of the object if the ACCEPT header requests JSON
    #  otherwise a plain-text representation of the object
    def return_shortcode(shortcode)
      if request.accept?('application/json') || request.accept?('application/vnd.api+json')
        response.headers['Content-Type'] = 'application/vnd.api+json'
        JSONAPI::Serializer.serialize(shortcode, fields: request.params['fields']).to_json
      else
        shortcode.name + ' (' + shortcode.destination + ') '
      end
    end

    # Returns a JSON formatted representation of a collection of shortcodes
    # @param shortcodes [Array<Shortcode>] the shortcodes to format into JSON
    # @return [String] a JSON representation of a collection of shortcodes.
    #  Note that when text/html is requested and error message is displayed.
    # @todo Perhaps this should display something instead of an error for plaintext?
    def return_shortcode_collection(shortcodes)
      if request.accept?('application/json') || request.accept?('application/vnd.api+json')
        response.headers['Content-Type'] = 'application/vnd.api+json'
        JSONAPI::Serializer.serialize(
          shortcodes,
          is_collection: true,
          fields: request.params['fields']
        ).to_json
      else
        'No Plaintext Representation Exists'
      end
    end

    # Returns a HTTP error code and formatted error message
    #
    # @param [Hash] opts the options to created the error
    # @option opts [Integer] :error_code (Defaults to 500) the error code to be returned
    # @option opts [String] :message (optional) the error message to accompany the error code
    # @option opts [String] :pointer (optional) a JSON Pointer (RFC6901) to the associated entity
    #  in the request document
    # @option opts [String] :parameter (optional) a string indicating which URI query parameter
    #  caused the error.
    def return_error(opts = {})
      opts[:error_code] = opts[:error_code] || 500
      opts[:message] =  opts[:message] || 'An Internal Error Occurred'
      if request.accept?('application/json') || request.accept?('application/vnd.api+json')
        response.headers['Content-Type'] = 'application/vnd.api+json'
        halt opts[:error_code], build_json_error(opts)
      else
        halt opts[:error_code], opts[:message]
      end
    end

    # Builds an error message JSON object
    #
    # @param [Hash] opts the options to create the JSON object
    # @option opts [Integer] :error_code the http error code that will accompany the message
    # @option opts [String] :message (optional) the error message
    # @option opts [String] :pointer (optional) A JSON Pointer (RRC6901) to the associated entity
    #   in the request document
    # @option opts [String] :parameter (optional) a string indicating which URI query parameter
    #   caused the error.
    # @return [String] a JSON string representing the error message
    def build_json_error(opts = {})
      json_body = { errors: [{ status: opts[:error_code] }] }
      json_body[:errors][0].store('message', opts[:message]) if opts[:message]
      if opts[:pointer]
        json_body[:errors][0].store(
          'source',
          build_json_error_source(
            opts[:pointer],
            opts[:parameter]
          )
        )
      end
      json_body.to_json
    end

    # Builds an error source message hash
    # @param pointer [String] A JSON Pointer (RRC6901) to the associated entity
    #   in the request document
    # @param parameter [String] (optional) a string indicating which URI query parameter
    #   caused the error.
    # @return [Hash]
    def build_json_error_source(pointer, parameter = nil)
      source = {}
      source.store('pointer', pointer)
      soorce.store('parameter', parameter) if parameter
      source
    end
  end
  # rubocop:enable Metrics/ClassLength
end
