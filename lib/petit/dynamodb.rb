module Petit
  # Namespace for Database connector classes
  module DB
    # Database abstraction class for shortcode CRUD operations.
    #   It is possible to rewrite this class to for a different database.
    #   To replace this class with your own database connector you'll need
    #   to replace the DATABASE constant in the shortcode class with your own.
    # @todo Investigate if there is a better way to do this.
    # rubocop:disable Metrics/ClassLength
    class DynamoDB
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
        resp.items.map { |item| Petit::Shortcode.new(item) }
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

        Petit::Shortcode.new(resp.item)
      end

      # Increment the access count for an object
      #
      # @param shortcode [Shortcode]
      # @return [Integer] the new access_count if successful
      # @return [Boolean] false if not successful
      def self.hit(shortcode)
        resp = Aws::DynamoDB::Client.new.update_item(
          table_name: Petit.configuration.db_table_name,
          key: { 'shortcode' => shortcode.name },
          return_values: 'ALL_NEW',
          return_consumed_capacity: 'NONE',
          update_expression: 'SET access_count = access_count + :one',
          expression_attribute_values: { ':one' => 1 }
        )
        resp.attributes['access_count']
      rescue Aws::DynamoDB::Errors::ValidationException
        return false
      end

      # Removes the object from the database
      #
      # @param shortcode [Shortcode]
      # @return [Hash] collection of attributes from object destroyed
      def self.destroy(shortcode)
        resp = Aws::DynamoDB::Client.new.delete_item(
          table_name: Petit.configuration.db_table_name, # required
          key: { # required
            'shortcode' => shortcode.name, # value <Hash,Array,String,Numeric,Boolean,IO,Set,nil>
          },
          return_values: 'ALL_OLD', # accepts NONE, ALL_OLD, UPDATED_OLD, ALL_NEW, UPDATED_NEW
        )
        resp.attributes
      end

      # Updates an existing object in the database.
      # To create new objects use {#save}.
      #
      # @param shortcode [Shortcode]
      # @return [Hash] resulting collection of object attributes after update
      # @raise [Petit::ShortcodeAccessError] when record to update does not exist
      # @raise [Petit::IncompleteObjectError] when the Shortcode fails validation
      def self.update(shortcode)
        time = Time.now.to_i
        begin
          resp = Aws::DynamoDB::Client.new.update_item(
            table_name: Petit.configuration.db_table_name,
            key: { 'shortcode' => shortcode.name },
            update_expression: 'SET destination = :new_destination,
              ssl = :new_ssl,
              updated_at = :new_updated_at',
            expression_attribute_values: {
              ':new_destination' => shortcode.destination,
              ':new_ssl' => shortcode.ssl?,
              ':new_updated_at' => time
            },
            return_values: 'ALL_NEW',
            return_consumed_capacity: 'INDEXES',
            return_item_collection_metrics: 'SIZE',
            condition_expression: 'attribute_exists(shortcode)'
          )
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

      # Validates and saves a new object to the database.
      # To update exisiting objects use {.update}.
      #
      # @param shortcode [Shortcode]
      # @return [Integer] the time that the save occurred
      # @raise [Petit::ShortcodeAccessError] when access is denied
      # @raise [Petit::IncompleteObjectError] when the Shortcode fails validation
      def self.save(shortcode)
        time = Time.now.to_i
        begin
          Aws::DynamoDB::Client.new.put_item(
            table_name: Petit.configuration.db_table_name,
            item: {
              'shortcode' => shortcode.name,
              'destination' => shortcode.destination,
              'ssl' => shortcode.ssl?,
              'access_count' => 0,
              'created_at' => time,
              'updated_at' => time
            },
            return_consumed_capacity: 'INDEXES',
            return_item_collection_metrics: 'SIZE',
            expected: { 'shortcode' => { exists: false } }
          )
          return time
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
    end
    # rubocop:enable Metrics/ClassLength
  end
end
