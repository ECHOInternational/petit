module Petit
  # Rack::Parsers class that specifies how to interpret a Rack::Request body
  class JSONapiParser
    # Required method from Rack::Parsers that encapsulates the logic for parsing the request body.
    # This parser simply strips off everything except the params that make up a Shortcode object.
    # This allows the JSON body to be converted to params which will behave just just form parameters.
    #
    # @param body [Object] the request body is passed to the call method
    # @return [Hash] key-value pairs for the attributes
    def call(body)
      json = JSON.parse(body)
      json['data']['attributes']
    end
  end
end
