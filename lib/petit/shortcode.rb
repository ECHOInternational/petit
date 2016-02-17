module Petit
  # The Shortcode class encapsulates a shortcode object.
  # Currently this class also contains the CRUD functions
  # for the AWS::DynamoDB backing store as well
  # @todo The ORM should be abstracted out of this class.
  class Shortcode
    require 'aws-sdk'
    require 'active_support/all'

    attr_reader :created_at, :updated_at, :access_count
    attr_accessor :name, :destination, :ssl

    # Shortcode instance initializer
    #
    # @param [Hash] params the collection of values by which to instantiate a Shortcode
    #   object. This is used primarily for generating object from database records.
    # @option params [String] :name The Shortcode
    # @option params [String] :shortcode The Shortcode (alias for name)
    # @option params [String] :destination The destination URL for the shortcode (Should not include http(s)://)
    # @option params [String, Integer, Boolean] :ssl Set protocol to http(false) or https(true)
    # @option params [Integer] :access_count The number of times a resource has been accessed
    # @option params [String] :created_at When the Shortcode was created
    # @option params [String] :updated_at The last time the Shortcode was modified
    def initialize(params = {})
      @dynamo_db_client = Aws::DynamoDB::Client.new
      create_from_params(params.with_indifferent_access)
    end

    # Sets the name of the Petit::Shortcode object and ensures it is all lowercase
    #
    # @param name [String] the name to assign the object
    # @return [String] the name of the object
    def name=(name)
      @name = name
      @name = @name.downcase if @name
    end

    # Sets the destination of the Petit::Shortcode object and ensures it is all lowercase
    #
    # @param destination [String] the destination to assign the object
    # @return [String], the destination of the object
    def destination=(destination)
      @destination = destination
      @destination = @destination.downcase if @destination
    end

    # Sets the ssl (https) flag for the Petit::Shortcode object
    #
    # @param ssl [String, Integer, Boolean] the value to set the ssl flag
    # @return [Boolean] the ssl flag value of the object
    def ssl=(ssl)
      @ssl = if ssl == true || ssl =~ /(true|t|yes|y|1)$/i
               true
             else
               false
             end
    end

    # Predicate method to return the SSL flag for the Petit::Shortcode Object
    #
    # @return [Boolean] the ssl flag value of the object
    def ssl?
      ssl
    end

    # Validates and saves a new object to the database.
    # To update exisiting objects use {#update}.
    #
    # @return [Boolean] TRUE if save is successful
    # @raise [Petit::ShortcodeAccessError] when access is denied
    # @raise [Petit::IncompleteObjectError] when the Shortcode fails validation
    # rubocop:disable Metrics/MethodLength
    def save
      time = Time.now.to_i
      begin
        @dynamo_db_client.put_item(
          table_name: Petit.configuration.db_table_name,
          item: {
            'shortcode' => @name,
            'destination' => @destination,
            'ssl' => ssl?,
            'access_count' => 0,
            'created_at' => time,
            'updated_at' => time
          },
          return_consumed_capacity: 'INDEXES',
          return_item_collection_metrics: 'SIZE',
          expected: { 'shortcode' => { exists: false } }
        )
        @created_at = time
        @updated_at = time
        @access_count = 0
        return true
      rescue Aws::DynamoDB::Errors::ConditionalCheckFailedException
        raise(
          Petit::ShortcodeAccessError,
          'Item already exists, cannot overwrite only update or delete.'
        )
      rescue Aws::DynamoDB::Errors::ValidationException
        raise(
          Petit::IncompleteObjectError,
          'Object must have both a name(shortcode) and a destination.'
        )
      end
    end
    # rubocop:enable Metrics/MethodLength

    # Updates an existing object in the database.
    # To create new objects use {#save}.
    #
    # @return [Hash] resulting collection of object attributes after update 
    # @raise [Petit::ShortcodeAccessError] when record to update does not exist
    # @raise [Petit::IncompleteObjectError] when the Shortcode fails validation
    # rubocop:disable Metrics/MethodLength
    def update
      time = Time.now.to_i
      begin
        resp = @dynamo_db_client.update_item(
          table_name: Petit.configuration.db_table_name,
          key: { 'shortcode' => @name },
          update_expression: 'SET destination = :new_destination,
            ssl = :new_ssl,
            new_updated_at = :new_updated_at',
          expression_attribute_values: {
            ':new_destination' => @destination,
            ':new_ssl' => ssl?,
            ':new_updated_at' => time
          },
          return_values: 'ALL_NEW',
          return_consumed_capacity: 'INDEXES',
          return_item_collection_metrics: 'SIZE',
          condition_expression: 'attribute_exists(shortcode)'
        )
        @updated_at = resp.attributes['updated_at'] if resp.attributes
        resp.attributes

      rescue Aws::DynamoDB::Errors::ConditionalCheckFailedException
        raise(
          Petit::ShortcodeAccessError,
          'Cannot update item. Item does not exist.'
        )
      rescue Aws::DynamoDB::Errors::ValidationException
        raise(
          Petit::IncompleteObjectError,
          'Object must have both a name(shortcode) and a destination.'
        )
      end
    end
    # rubocop:enable Metrics/MethodLength

    # Removes the object from the database
    #
    # @return [Hash] collection of attributes from object destroyed
    def destroy
      resp = @dynamo_db_client.delete_item(
        table_name: Petit.configuration.db_table_name, # required
        key: { # required
          'shortcode' => @name, # value <Hash,Array,String,Numeric,Boolean,IO,Set,nil>
        },
        return_values: 'ALL_OLD', # accepts NONE, ALL_OLD, UPDATED_OLD, ALL_NEW, UPDATED_NEW
      )
      resp.attributes
    end

    # Increment the access count for the object
    #
    # @return [Boolean] TRUE if the increase succeeded, FALSE if an error occurred
    def hit
      resp = @dynamo_db_client.update_item(
        table_name: Petit.configuration.db_table_name,
        key: { 'shortcode' => @name },
        return_values: 'ALL_NEW',
        return_consumed_capacity: 'NONE',
        update_expression: 'SET access_count = access_count + :one',
        expression_attribute_values: { ':one' => 1 }
      )
      @access_count = resp.attributes['access_count']
      return true
    rescue Aws::DynamoDB::Errors::ValidationException
      return false
    end

    # Returns basic JSON representation of the object
    #
    # @return [String] a JSON string representing the object
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

    # Finds and returns a Shortcode object by its name
    #
    # @param name [String] the value to search for
    # @return [Shortcode] if matching record is found
    # @return [Nil] if no matching record is found
    def self.find(name)
      dynamo_db_client = Aws::DynamoDB::Client.new

      resp = dynamo_db_client.get_item(
        table_name: Petit.configuration.db_table_name,
        key: { 'shortcode' => name.to_s.downcase },
        consistent_read: false,
        return_consumed_capacity: 'NONE'
      )

      return nil if resp.item.nil?

      new(resp.item)
    end

    # Alias to the {find} method
    #
    # @param name [String] the value to search for
    # @return [Shortcode] if matching record is found
    # @return [Nil] if no matching record is found   
    def self.find_by_name(name)
      find(name)
    end

    # Finds and returns an array of Shortcode objects by their destination
    #
    # @param destination [String] the value to search for
    # @return [Array<Shortcode>] zero or more shortcode results for the search
    def self.find_by_destination(destination)
      dynamo_db_client = Aws::DynamoDB::Client.new

      resp = dynamo_db_client.query(
        table_name: Petit.configuration.db_table_name,
        index_name: 'destinationIndex',
        select: 'ALL_PROJECTED_ATTRIBUTES',
        consistent_read: false,
        return_consumed_capacity: 'NONE',
        key_condition_expression: 'destination = :destinationQuery',
        expression_attribute_values: {
          ':destinationQuery' => destination.to_s.downcase
        }
      )
      resp.items.map { |item| new(item) }
    end

    # Provides an available randomized string to use as a name for a shortcode.
    # If an available name is not immediately found the length
    # will be increased until an available name is found.
    #
    # @param size [Integer] minimum number of characters to return
    # @return [String] an available name
    def self.suggest(size = 6)
      return nil unless size > 0
      suggestion = generate_random_string(size)
      return suggestion if find_by_name(suggestion).nil?
      suggest(size + 1)
    end

    # Private method called by initialize for mapping parameters from a hash to
    #   object parameters
    #
    # @param params [HashWithIndifferentAccess] is a collection of values to be
    #   validated and applied to the object instance
    def create_from_params(params)
      self.name = params[:name] || params[:shortcode]
      self.destination = params[:destination]
      self.ssl = params[:ssl]
      @access_count = params[:access_count] || nil
      @created_at = Time.at(params[:created_at]) if params[:created_at]
      @updated_at = Time.at(params[:updated_at]) if params[:updated_at]
    end

    private :create_from_params

    # Generates a random string from a specific set of characters
    #
    # @param size [Integer] specifies how many characters the resulting string should contain
    # @return [String] a random string of characters from the specified set of characters.
    def self.generate_random_string(size)
      charset = %w( 2 3 4 6 7 9 a c d e f g h j k m n p q r t w x y z)
      (0...size).map { charset.to_a[rand(charset.size)] }.join
    end

    private_class_method :generate_random_string
  end

  # Shortcode exception class that indicates a database access exception,
  # these are usually raised when access to a record is impossible or
  # when access is denied.
  class ShortcodeAccessError < StandardError
  end

  # Shortcode exception class that indicates that an incomplete record
  # has been submitted to the database, these should be raised when an
  # object fails validation
  class IncompleteObjectError < StandardError
  end
end
