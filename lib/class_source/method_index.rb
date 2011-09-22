module ClassSource
  # An index of all the methods in the target class
  class MethodIndex
    def initialize(target_class)
      @target_class = target_class
    end


    # @return [Array] An array of [file_path, line_number] tuples for all unique methods of the class
    def locations
      @locations ||= (unique.map do |m|
        @target_class.instance_method(m).source_location
      end + klass.unique.map do |m|
        @target_class.method(m).source_location
      end).compact
    end

    # @return [Array] An array of method names unique to or overridden in this class, not inherited from its ancestors or singleton_class ancestors.
    def unique
      uniquely_named_methods = all(:include_inherited_methods => false)
      overridden_methods = (all - uniquely_named_methods).select do |m|
        @target_class.instance_method(m).source_location != @target_class.superclass.instance_method(m).source_location
      end
      overridden_methods + uniquely_named_methods
    end


    # @return [Array] An array of method names for all instance methods in the class
    def all(options={})
      include_inherited_methods = options.has_key?(:include_inherited_methods) ? options[:include_inherited_methods] : true
      target = options[:target] || @target_class
      target.public_instance_methods(include_inherited_methods) +
        target.private_instance_methods(include_inherited_methods) +
        target.protected_instance_methods(include_inherited_methods)
    end

    # @return [ClassSource::ClassMethodIndex] A index of class methods
    # @private
    def klass
      ClassMethodIndex.new(@target_class)
    end

  end
end
