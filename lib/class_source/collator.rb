require 'ruby_parser'

module ClassSource
  class Collator
    def initialize(target_class, index)
      @klass = target_class
      @source = index
    end

    def to_hash(options = {})
      full_sources = @source.locations(options).inject({}) do |results, location|
        results[ location ] = source_helper(location)
        results
      end

      return full_sources unless options[:include_nested] == false
      full_sources.inject({}) do |clean_sources, (location, source)|
        if nested_class_line_ranges[location.first]
          complete_file = full_file(location)
          target_range =  (location.last - 1)..(location.last + source.lines.count - 2)
          clean_sources[location] = complete_file.lines.to_a.select.with_index do |line, index|
            target_range.include?(index) &&
            nested_class_line_ranges[location.first].all? { |range| !range.include?(index) }
          end.join("")
        else
          clean_sources[location] = source
        end
        clean_sources
      end
    end

    def nested_class_line_ranges
      nested_classes = @klass.constants.select { |c| @klass.const_get(c).is_a?(Class) }.map {|c| @klass.const_get(c) }
      return @nested_class_ranges if @nested_class_ranges
      @nested_class_ranges = {}
      nested_classes.each do |klass| 
        # (klass.source_location.last-1)..(klass.source_location.last + klass.source.lines.count - 2)
        klass.__source__.all.each do |(file, line), source| 
          @nested_class_ranges[file] ||= []
          @nested_class_ranges[file] << ((line - 1)..(line + source.lines.count - 2))
        end
      end

      @nested_class_ranges
    end

    def full_file(location)
      File.read(location.first)
    end

    # source_helper and valid_expression? are lifted from method_source
    # (c) 2011 John Mair (banisterfiend)
    def source_helper(source_location)
      return nil if !source_location.is_a?(Array)

      file_name, line = source_location
      File.open(file_name) do |file|
        (line - 1).times { file.readline }

        code = ""
        loop do
          val = file.readline
          code << val

          return code if valid_expression?(code)
        end
      end
    end


    def valid_expression?(code)
      RubyParser.new.parse(code)
    rescue Racc::ParseError, SyntaxError
      false
    else
      true
    end

  end
end
