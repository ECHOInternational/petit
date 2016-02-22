module Petit
  # The Shortcode class encapsulates a shortcode object.
  class Shortcode
    require 'aws-sdk'
    require 'active_support/all'

    attr_reader :created_at, :updated_at, :access_count
    attr_accessor :name, :destination, :ssl

    # Defines the database connector class that should be employed to persist shortcode objects.
    DATABASE = Petit::DB::DynamoDB

    # Shortcode instance initializer
    #
    # @param [Hash] params the collection of values by which to instantiate a Shortcode
    #   object. This is used primarily for generating object from database records.
    # @option params [String] :name The Shortcode
    # @option params [String] :shortcode The Shortcode (alias for name)
    # @option params [String] :destination The destination URL for the shortcode
    #  (Should not include http(s)://)
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
    def save
      save_time = DATABASE.save(self)
      if save_time
        @created_at = save_time
        @updated_at = save_time
        @access_count = 0
        return true
      end
    end

    # Updates an existing object in the database.
    # To create new objects use {#save}.
    #
    # @return [Hash] resulting collection of object attributes after update
    # @raise [Petit::ShortcodeAccessError] when record to update does not exist
    # @raise [Petit::IncompleteObjectError] when the Shortcode fails validation
    def update
      stored_values = DATABASE.update(self)
      @updated_at = stored_values['updated_at']
      stored_values
    end

    # Removes the object from the database
    #
    # @return [Hash] collection of attributes from object destroyed
    def destroy
      DATABASE.destroy(self)
    end

    # Increment the access count for the object
    #
    # @return [Integer] current access count
    def hit
      @access_count = DATABASE.hit(self) || @access_count
    end

    # Finds and returns a Shortcode object by its name
    #
    # @param name [String] the value to search for
    # @return [Shortcode] if matching record is found
    # @return [Nil] if no matching record is found
    def self.find(name)
      DATABASE.find(name)
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
      DATABASE.find_by_destination(destination)
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
