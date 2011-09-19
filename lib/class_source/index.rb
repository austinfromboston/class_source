module ClassSource
  class Index
    def initialize(target_class)
      @target_class = target_class
    end

    def methods
      @method_details ||= MethodIndex.new(@target_class)
    end

    def locations
      @target_class.source_locations
    end

    def to_s
      @target_class.source
    end

  end
end
