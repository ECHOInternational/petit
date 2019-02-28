require 'jsonapi-serializers'

module Petit
  # Serializes Petit::Shortcode objects into JSONAPI compliant JSON
  #   this is essentially a configuration file for specifying how the
  #   JSON representation should be built from a Shortcode object.
  class ShortcodeSerializer
    include JSONAPI::Serializer

    attribute :name
    attribute :destination
    attribute :ssl

    # Override the JSON:API "id"
    # We use the object's name as that is the primary key for our nosql database
    # @return [String] must be a string to conform to the JSON:API spec.
    def id
      object.name
    end

    attribute :qr_code do
      Petit::QRcode.generate(Petit.configuration.service_base_url + '/' + object.name)
    end

    attribute :generated_link do
      Petit.configuration.service_base_url + '/' + object.name
    end

    # Set the base URL for the API
    # @return [String] the base URL for the API
    def base_url
      Petit.configuration.api_base_url + '/api/v1'
    end

    # Sets meta parameters
    # @return [Hash] key-value pairs for each additional property to be returned in the
    # JSON object.
    def meta
      {
        access_count: object.access_count,
        created_at: object.created_at,
        updated_at: object.updated_at,
        generated_link: Petit.configuration.service_base_url + '/' + object.name
      }
    end
  end
end
