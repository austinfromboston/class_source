module ClassSource
  class MethodIndex
    def initialize(target_class)
      @target_class = target_class
    end

    def locations
      @locations ||= (unique.map do |m|
        @target_class.instance_method(m).source_location
      end + klass.unique.map do |m|
        @target_class.method(m).source_location
      end).compact
    end

    def unique
      uniquely_named_methods = all(:include_inherited_methods => false)
      overridden_methods = (all - uniquely_named_methods).select do |m|
        @target_class.instance_method(m).source_location != @target_class.superclass.instance_method(m).source_location
      end
      overridden_methods + uniquely_named_methods
    end


    def all(options={})
      include_inherited_methods = options.has_key?(:include_inherited_methods) ? options[:include_inherited_methods] : true
      target = options[:target] || @target_class
      target.public_instance_methods(include_inherited_methods) +
        target.private_instance_methods(include_inherited_methods) +
        target.protected_instance_methods(include_inherited_methods)
    end

    def klass
      ClassMethodIndex.new(@target_class)
    end

    class ClassMethodIndex
      def initialize(target_class)
        @target_class = target_class
      end

      def unique
        uniquely_named + overridden - extended
      end

      def extended 
        @target_class.singleton_class.ancestors.map do |mod|
          mod.instance_methods.select { |m| mod.instance_method(m).source_location == @target_class.method(m).source_location }
        end.flatten
      end

      def uniquely_named
        @target_class.singleton_methods(false)
      end

      def overridden
        (@target_class.methods - uniquely_named).select do |m|
          !ancestral_sources(m).include?(@target_class.method(m).source_location)
        end
      end

      def ancestral_sources(method)
        superclasses.map { |mod| mod.respond_to?(method) && mod.method(method).source_location }.compact
      end

      def superclasses
        @target_class.ancestors - [@target_class]
      end

    end

  end
end
