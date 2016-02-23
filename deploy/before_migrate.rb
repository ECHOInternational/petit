require 'aws-sdk'

# We don't need full database migration for a nosql database, but we do want to make sure
# the database has been created according to the configuration.

# Get the name of our database from the environment. (|| from CHEF)
# NOTE: if you are hard-coding the table name in the config file (WHY?) you'll need to
# change this to match before you deploy.
table_name = ENV['DB_TABLE_NAME'] || new_resource.environment['DB_TABLE_NAME']

log 'message' do
	message 'Checking for, and creating table:' + table_name
	level :info
end

table_definition = {
  attribute_definitions: [ # required
    {
      attribute_name: 'shortcode', # required
      attribute_type: 'S', # required, accepts S, N, B
    },
    {
      attribute_name: 'destination', # required
      attribute_type: 'S', # required, accepts S, N, B
    },
    # {
    #   attribute_name: "ssl", # required
    #   attribute_type: "B", # required, accepts S, N, B
    # },
    # {
    #   attribute_name: "accessCount", # required
    #   attribute_type: "N", # required, accepts S, N, B
    # },
  ],
  table_name: table_name, # required
  key_schema: [ # required
    {
      attribute_name: 'shortcode', # required
      key_type: 'HASH', # required, accepts HASH, RANGE
    }
  ],
  global_secondary_indexes: [
    {
      index_name: 'destinationIndex', # required
      key_schema: [ # required
        {
          attribute_name: 'destination', # required
          key_type: 'HASH', # required, accepts HASH, RANGE
        }
      ],
      projection: { # required
        projection_type: 'ALL', # accepts ALL, KEYS_ONLY, INCLUDE
      },
      provisioned_throughput: { # required
        read_capacity_units: 1, # required
        write_capacity_units: 1, # required
      }
    }
  ],
  provisioned_throughput: { # required
    read_capacity_units: 1, # required
    write_capacity_units: 1, # required
  },
  stream_specification: {
    stream_enabled: false
  }
}

dynamo_db_client = AWS::DynamoDB::Client.new

log 'message' do
	message 'Created DynamoDB client'
	level :info
end


begin
  dynamo_db_client.create_table(table_definition)
rescue AWS::DynamoDB::Errors::ResourceInUseException
  log 'message' do
  	message 'Table Already Exists'
  	level :info
  end
end

log 'message' do
	message 'Checking Table'
	level :info
end

begin
  dynamo_db_client.describe_table(
    table_name: table_definition[:table_name]
  )
rescue AWS::DynamoDB::Errors::ResourceNotFoundException
  log 'failure' do
	message 'Table Does Not Exist - Check Configurations'
	level :warn
	end
end
