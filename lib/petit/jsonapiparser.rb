class JSONapiParser
	def call(body)
		json = JSON.parse(body)
		json["data"]["attributes"]
	end
end