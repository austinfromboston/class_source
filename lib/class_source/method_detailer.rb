module ClassSource
  module MethodDetailer

    def method_locations
      @method_locations ||= (unique_methods.map do |m|
        instance_method(m).source_location
      end + unique_class_methods.map do |m|
        method(m).source_location
      end).compact
    end
    
    def unique_class_methods
      uniquely_named_class_methods = singleton_methods(false)
      overridden_class_methods = (methods - uniquely_named_class_methods).select do |m|
        ancestral_sources = (ancestors - [self]).map { |mod| mod.respond_to?(m) && mod.method(m).source_location }.compact
        !ancestral_sources.include?(method(m).source_location)
      end
      unique_methods = uniquely_named_class_methods + overridden_class_methods 
      singleton_class.ancestors.inject(unique_methods) do |unique_methods, mod|
        unique_methods - mod.instance_methods.select { |m| mod.instance_method(m).source_location == method(m).source_location }
      end
    end

    def unique_methods
      uniquely_named_methods = all_methods(include_inherited_methods: false)
      overridden_methods = (all_methods - uniquely_named_methods).select do |m|
        instance_method(m).source_location != superclass.instance_method(m).source_location
      end
      overridden_methods + uniquely_named_methods
    end

    def all_methods(options={})
      include_inherited_methods = options.has_key?(:include_inherited_methods) ? options[:include_inherited_methods] : true
      target = options[:target] || self
      target.public_instance_methods(include_inherited_methods) +
        target.private_instance_methods(include_inherited_methods) +
        target.protected_instance_methods(include_inherited_methods)
    end

    def source_files(options={})
      @source_files ||= method_locations.map(&:first).uniq
      return @source_files + [options[:file]] if options[:file]
      @source_files
    end
  end
end
