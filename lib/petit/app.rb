require 'sinatra/base'
require 'rack/parser'
require_relative 'jsonapiparser'
require 'pp'
require 'json'
require 'pry'

module Petit
  class App < Sinatra::Application
    use Rack::Parser, parsers: {
      'application/vnd.api\+json' => JSONapiParser.new
    }

    get '/' do
      redirect_to_not_found
    end

    get '/:shortcode' do
      response = Petit::Shortcode.find_by_name(params[:shortcode])
      if response.nil?
        redirect_to_not_found
      else
        redirect_to(response)
      end
    end

    get '/api/v1/shortcodes' do
      require_ssl

      if params[:destination]
        shortcodes = Petit::Shortcode.find_by_destination(params[:destination])
        return_shortcode_collection(shortcodes)
      else
        return_error 400, 'Must supply destination argument.'
      end
    end

    get '/api/v1/suggestion' do
      require_ssl
      return_suggestion
    end

    get '/api/v1/shortcodes/:shortcode' do
      require_ssl

      shortcode = Petit::Shortcode.find_by_name(params[:shortcode])

      if shortcode.nil?
        return_not_found
      else
        return_shortcode(shortcode)
      end
    end

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
        return_error 409, e.message
      rescue Petit::IncompleteObjectError => e
        return_error 400, e.message
      else
        headers(
          'Location' => Petit.configuration.api_base_url + '/api/v1/shortcodes/' + new_shortcode.name
        )
        shortcode = Petit::Shortcode.find_by_name(new_shortcode.name)
        return 201,  return_shortcode(shortcode)
      end
    end

    post '/api/v1/shortcodes/:shortcode' do
      require_ssl

      response = Petit::Shortcode.find_by_name(params[:shortcode])
      if response.nil?
        return_error 404, 'Records must be created on the collection.'
      else
        return_error 409, 'Record Exists: Cannot modify record using POST, use PUT.'
      end
    end

    put '/api/v1/shortcodes/:shortcode' do
      require_ssl

      shortcode = Petit::Shortcode.find_by_name(params[:shortcode])
      if shortcode.nil?
        return_error 404, 'Record does not exist.'
      else
        shortcode.destination = params[:destination] || shortcode.destination
        shortcode.ssl = params[:ssl] || shortcode.ssl
        begin
          shortcode.update
          return_shortcode(shortcode)
        rescue Petit::IncompleteObjectError => e
          return_error 400, e.message
        end
      end
    end

    delete '/api/v1/shortcodes/:shortcode' do
      require_ssl
      shortcode = Petit::Shortcode.find_by_name(params[:shortcode])
      if shortcode.nil?
        return_error 404, 'Record does not exist.'
      else
        shortcode.destroy
        if request.accept? 'application/json'
          response.headers['Content-Type'] = 'application/vnd.api+json'
          '{}'
        else
          'Deleted'
        end
      end
    end

    def require_ssl
      return_error 403, 'HTTPS Required' unless request.secure?
    end

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

    def redirect_to_not_found
      if Petit.configuration.not_found_destination
        redirect Petit.configuration.not_found_destination, 303
      else
        return_not_found
      end
    end

    def return_not_found
      return_error(404, 'Not Found')
    end

    def return_suggestion
      suggestion = Petit::Shortcode.suggest
      if request.accept? 'application/json'
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

    def return_shortcode(shortcode)
      if request.accept? 'application/json'
        response.headers['Content-Type'] = 'application/vnd.api+json'
        JSONAPI::Serializer.serialize(shortcode).to_json
      else
        shortcode.name + ' (' + shortcode.destination + ') '
      end
    end

    def return_shortcode_collection(shortcodes)
      if request.accept? 'application/json'
        response.headers['Content-Type'] = 'application/vnd.api+json'
        JSONAPI::Serializer.serialize(shortcodes, is_collection: true).to_json
      else
        'No Plaintext Representation Exists'
      end
    end

    def return_error(error_code = 500, message = nil, pointer = nil, parameter = nil)
      if request.accept? 'application/json'
        response.headers['Content-Type'] = 'application/vnd.api+json'
        json_body = {
          errors: [
            {
              status: error_code
            }
          ]
        }
        json_body[:errors][0].store('message', message) if message
        if pointer
          json_body[:errors][0].store('source', {})
          json_body[:errors][0]['source'].store('pointer', pointer)
          json_body[:errors][0]['source'].store('parameter', parameter) if parameter
        end
        halt error_code, json_body.to_json
      else
        halt error_code, message
      end
    end
  end
end
