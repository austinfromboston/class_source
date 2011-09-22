module ClassSource
  # An index of all source code available for a class
  class Index
    # @param [Hash] options, may include a :file => 'path_to_expected_source' param for tricky classes.
    #   Classes with no methods will need this hint to be sourced correctly.
    def initialize(target_class, options = {})
      @target_class = target_class
      @options = options
    end

    # This returns a string containing all the class' source code.
    # Order is not guaranteed to match evaluation order.
    # @param [Hash] options may contain a key :include_nested => false
    #   to return the source without the body of any nested classes
    # @return [String] the joined value of all source code for the class
    def to_s(options={})
      all(options).values.join("")
    end

    # Returns a hash of source code fragments indexed by location
    # @param (see #to_s)
    # @return [Hash] a hash of source code fragments with keys being a tuple in the form of [file_path, line_number]
    def all(options={})
      @collator ||= Collator.new(@target_class, self).to_hash(options)
    end

    # Returns an array of source code locations
    # @return [Array] an array of tuples in the form of [file_path, line_number]
    def locations(options={})
      locator.to_a
    end

    # Convenience method for comparing sources as string values
    # @private
    def ==(value)
      to_s == value
    end

    # Returns an index of all methods found for the class
    # @private
    def methods
      @method_details ||= MethodIndex.new(@target_class)
    end

    # Returns an index of all methods found for the class
    # @private
    def class_methods
      methods.klass
    end

    # Returns an instance of the source locator object that searches out source locations
    # @private
    def locator
      @locator ||= Locator.new(@target_class, @options)
    end

    # Returns an array of file containing relevant source code
    # @private
    def files
      locator.files
    end

  end
end
