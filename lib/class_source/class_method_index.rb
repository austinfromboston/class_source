module ClassSource
  # An index of all class methods available for a class
  class ClassMethodIndex
    def initialize(target_class)
      @target_class = target_class
    end

    # @return [Array] An array of method names unique to or overridden in this class, not inherited from its ancestors or singleton_class ancestors.
    def unique
      uniquely_named + overridden - extended
    end

    # @return [Array] An array of method names for all methods included into a class via class extension.
    def extended
      @target_class.singleton_class.ancestors.map do |mod|
        mod.instance_methods.select { |m| mod.instance_method(m).source_location == @target_class.method(m).source_location }
      end.flatten
    end

    # @return [Array] An array of method names introduced for the first time in the current class
    def uniquely_named
      @target_class.singleton_methods(false)
    end

    # @return [Array] An array of method names with new source in this class vs its ancestors
    def overridden
      (@target_class.methods - uniquely_named).select do |m|
        !ancestral_sources(m).include?(@target_class.method(m).source_location)
      end
    end

    # @return [Array] An array of ancestral sources for a given method
    def ancestral_sources(method)
      superclasses.map { |mod| mod.respond_to?(method) && mod.method(method).source_location }.compact
    end

    # All ancestors of the target class
    # @return[Array] An array of classes and modules
    def superclasses
      @target_class.ancestors - [@target_class]
    end

  end
end
