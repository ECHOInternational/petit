
# At time of writing the OPSWORKS Chef implementation uses the V1 of the aws-sdk
# we want the V2 so we purge out the one we don't want (or it interferes)
# and we install the one we need locally to CHEF
chef_gem 'aws-sdk' do
	action :purge
end

chef_gem 'aws-sdk' do
	version '~> 2'
	action :install
end

require 'aws-sdk'

# We don't need full database migration for a nosql database, but we do want to make sure
# the database has been created according to the configuration.

# Pull in the environment variables needed to create the database table
table_name = ENV['DB_TABLE_NAME'] || new_resource.environment['DB_TABLE_NAME']
aws_region = ENV['AWS_REGION'] || new_resource.environment['AWS_REGION']
aws_access_key_id = ENV['AWS_ACCESS_KEY_ID'] || new_resource.environment['AWS_ACCESS_KEY_ID']
aws_secret_access_key = ENV['AWS_SECRET_ACCESS_KEY'] || new_resource.environment['AWS_SECRET_ACCESS_KEY']

dynamo_db_client = Aws::DynamoDB::Client.new(
	region: aws_region,
	access_key_id: aws_access_key_id,
	secret_access_key: aws_secret_access_key
)

log 'message' do
	message 'Created DynamoDB client'
	level :info
end



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

begin
  dynamo_db_client.create_table(table_definition)
rescue Aws::DynamoDB::Errors::ResourceInUseException
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
rescue Aws::DynamoDB::Errors::ResourceNotFoundException
  log 'failure' do
	message 'Table Does Not Exist - Check Configuration'
	level :warn
	end
end
