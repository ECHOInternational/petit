class Shortcode
	require 'aws-sdk'
	require 'active_support/all'

	attr_reader :created_at, :updated_at, :access_count, :name, :destination, :ssl

	def initialize(params = {})
		@dynamoDBclient = Aws::DynamoDB::Client.new

		name = params.with_indifferent_access[:name] || params.with_indifferent_access[:shortcode]
		
		self.name=(name)
		self.destination=(params.with_indifferent_access[:destination])
		self.ssl=(params.with_indifferent_access[:ssl])

		@access_count = params.with_indifferent_access[:access_count] || nil
		
		unless params.with_indifferent_access[:created_at].nil?
			@created_at = Time.at(params.with_indifferent_access[:created_at])
		else
			@created_at = nil
		end

		unless params.with_indifferent_access[:updated_at].nil?
			@updated_at = Time.at(params.with_indifferent_access[:updated_at])
		else
			@updated_at = nil
		end
	end

	def name=(str)
		@name = str
		@name = @name.downcase if @name
	end

	def destination=(str)
		@destination = str
		@destination = @destination.downcase if @destination
	end

	def ssl=(val)
		if val == true || val =~ (/(true|t|yes|y|1)$/i)
			@ssl = true
		else
			@ssl = false
		end
	end

	def ssl?
		ssl
	end

	def save
		time = Time.now.to_i
		begin
			@dynamoDBclient.put_item({
			  table_name: Petit.configuration.db_table_name, # required
			  item: { # required
			    "shortcode" => @name, # value <Hash,Array,String,Numeric,Boolean,IO,Set,nil>
			    "destination" => @destination,
			    "ssl" => ssl?,
			    "access_count" => 0,
			    "created_at" => time,
			    "updated_at" => time
			  },	
			  return_consumed_capacity: "INDEXES", # accepts INDEXES, TOTAL, NONE
			  return_item_collection_metrics: "SIZE", # accepts SIZE, NONE
			  expected: {"shortcode" => {exists: false}}
			})
			@created_at = time
			@updated_at = time
			@access_count = 0
			return true
		rescue Aws::DynamoDB::Errors::ConditionalCheckFailedException
			raise ShortcodeErrors::ShortcodeAccessError.new("Item already exists, cannot overwrite only update or delete.")
		rescue Aws::DynamoDB::Errors::ValidationException
			raise ShortcodeErrors::IncompleteObjectError.new("Object must have both a name(shortcode) and a destination.")
		end
	end

	def update
		time = Time.now.to_i
		begin
			resp = @dynamoDBclient.update_item({
			  table_name: Petit.configuration.db_table_name, # required
			  key: {
				"shortcode" => @name
			  },
			  update_expression: "SET destination = :new_destination, ssl = :new_ssl, new_updated_at = :new_updated_at",
			  expression_attribute_values: {
			  	":new_destination" => @destination,
			  	":new_ssl" => ssl?,
			  	":new_updated_at" => time
			  },
			  return_values: "ALL_NEW",
			  return_consumed_capacity: "INDEXES", # accepts INDEXES, TOTAL, NONE
			  return_item_collection_metrics: "SIZE", # accepts SIZE, NONE
			  condition_expression: "attribute_exists(shortcode)"
			})
			@updated_at = resp.attributes['updated_at'] if resp.attributes
			resp.attributes
		rescue Aws::DynamoDB::Errors::ConditionalCheckFailedException
			raise ShortcodeErrors::ShortcodeAccessError.new("Cannot update item. Item does not exist.")
		rescue Aws::DynamoDB::Errors::ValidationException
			raise ShortcodeErrors::IncompleteObjectError.new("Object must have both a name(shortcode) and a destination.")
		end
	end

	def destroy
		resp = @dynamoDBclient.delete_item({
		  table_name: Petit.configuration.db_table_name, # required
		  key: { # required
		    "shortcode" => @name, # value <Hash,Array,String,Numeric,Boolean,IO,Set,nil>
		  },
		  return_values: "ALL_OLD", # accepts NONE, ALL_OLD, UPDATED_OLD, ALL_NEW, UPDATED_NEW
		})
		return resp.attributes
	end

	def hit
		begin
			resp = @dynamoDBclient.update_item({
			  table_name: Petit.configuration.db_table_name, # required
			  key: { # required
			    "shortcode" => @name, # value <Hash,Array,String,Numeric,Boolean,IO,Set,nil>
			  },
			  return_values: "ALL_NEW", # accepts NONE, ALL_OLD, UPDATED_OLD, ALL_NEW, UPDATED_NEW
			  return_consumed_capacity: "NONE", # accepts INDEXES, TOTAL, NONE
			  update_expression: "SET access_count = access_count + :one",
			  expression_attribute_values: {
			    ":one" => 1, # value <Hash,Array,String,Numeric,Boolean,IO,Set,nil>
			  },
			})
			@access_count = resp.attributes["access_count"]
			return true
		rescue Aws::DynamoDB::Errors::ValidationException
			return false
		end
	end

	def to_json(*a)
	  {
	  	name: @name,
	  	created_at: @created_at,
	  	updated_at: @updated_at,
	  	access_count: @access_count,
	  	destination: @destination,
	  	ssl: @ssl
	  }.to_json(*a)
	end

	def self.find(name)
		dynamoDBclient = Aws::DynamoDB::Client.new

		resp = dynamoDBclient.get_item({
		  table_name: Petit.configuration.db_table_name, # required
		  key: { # required
		    "shortcode" => name.to_s.downcase, # value <Hash,Array,String,Numeric,Boolean,IO,Set,nil>
		  },
		  consistent_read: false,
		  return_consumed_capacity: "NONE", # accepts INDEXES, TOTAL, NONE
		})

		if resp.item == nil
			return nil
		else
			return self.new(resp.item)
		end
	end

	def self.find_by_name(name)
		return self.find(name)
	end

	def self.find_by_destination(destination)
		dynamoDBclient = Aws::DynamoDB::Client.new

		resp = dynamoDBclient.query({
		  table_name: Petit.configuration.db_table_name, # required
		  index_name: "destinationIndex",
		  select: "ALL_PROJECTED_ATTRIBUTES", # accepts ALL_ATTRIBUTES, ALL_PROJECTED_ATTRIBUTES, SPECIFIC_ATTRIBUTES, COUNT
		  consistent_read: false,
		  return_consumed_capacity: "NONE", # accepts INDEXES, TOTAL, NONE
		  key_condition_expression: "destination = :destinationQuery",
		  expression_attribute_values: {
		    ":destinationQuery" => destination.to_s.downcase, # value <Hash,Array,String,Numeric,Boolean,IO,Set,nil>
		  },
		})
		resp.items.map {|item| self.new(item)}
	end
end

module ShortcodeErrors
	class ShortcodeAccessError < StandardError
	end
	class IncompleteObjectError < StandardError
	end
end