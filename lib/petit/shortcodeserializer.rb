require 'jsonapi-serializers'

class ShortcodeSerializer

	include JSONAPI::Serializer

	attribute :name
	attribute :destination
	attribute :ssl

	def id
		object.name
	end

	def base_url
		Petit.configuration.api_base_url + "/api/v1"
	end

	def meta
		{
			access_count: object.access_count,
			created_at: object.created_at,
			updated_at: object.updated_at,
			generated_link: Petit.configuration.service_base_url + "/" + object.name
		}
	end
end