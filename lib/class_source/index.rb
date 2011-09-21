module ClassSource
  class Index
    def initialize(target_class, options = {})
      @target_class = target_class
      @options = options
    end

    def to_s(options={})
      all(options).values.join("")
    end

    def ==(value)
      to_s == value
    end

    def all(options={})
      @collator ||= Collator.new(@target_class, self).to_hash(options)
    end

    def locations(options={})
      locator.to_a
    end

    def methods
      @method_details ||= MethodIndex.new(@target_class)
    end

    def class_methods
      methods.klass
    end

    def locator
      @locator ||= Locator.new(@target_class, @options)
    end

    def files
      locator.files
    end

  end
end
