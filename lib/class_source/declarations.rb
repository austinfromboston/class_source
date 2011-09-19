module ClassSource
  class Declarations
    def self.[](key)
      @declarations ||= {}
      @declarations[key]
    end

    def self.add(klass_name, locations)
      @declarations ||= {}
      @declarations[klass_name] ||= []
      @declarations[klass_name] += locations
    end

    def self.save(declarations)
      declarations.each do |klass_name, locations|
        add(klass_name, locations)
      end
    end
  end
end

