require 'ruby_parser'

module ClassSource
  # Responsible for collating class source information into a clear readable hash of source values.
  class Collator
    def initialize(target_class, index)
      @klass = target_class
      @source = index
    end

    # @return [Hash]  A hash with keys of [file_path, line_number] tuples pointing to values of source code segments
    def to_hash(options = {})
      return sources_without_nesting if options[:include_nested] == false
      @source.locations(options).inject({}) do |results, location|
        results[ location ] = source_helper(location)
        results
      end

    end

    # @private
    # @return [Hash] A hash of sources filtered for the source of any nested classes
    def sources_without_nesting
      @source.locations.inject({}) do |clean_sources, location|
        source = source_helper(location)
        if nested_class_line_ranges[location.first]
          clean_sources[location] = source_without_nesting(location, source)
        else
          clean_sources[location] = source
        end
        clean_sources
      end
    end

    # @private
    # @return [Hash] A source string with the contained nested class values removed
    def source_without_nesting(location, source)
      complete_file = full_file(location)
      target_range =  (location.last - 1)..(location.last + source.lines.count - 2)
      complete_file.lines.to_a.select.with_index do |line, index|
        target_range.include?(index) &&
        nested_class_line_ranges[location.first].all? { |range| !range.include?(index) }
      end.join("")
    end

    # @return a hash of nested data within the class source based on existing class constants
    # @private
    def nested_class_line_ranges
      nested_classes = @klass.constants.select { |c| @klass.const_get(c).is_a?(Class) }.map {|c| @klass.const_get(c) }
      return @nested_class_ranges if @nested_class_ranges
      @nested_class_ranges = nested_classes.inject({}) do |ranges, nested_klass| 
        nested_klass.__source__.all.each do |(file, line), source| 
          ranges[file] ||= []
          ranges[file] << ((line - 1)..(line + source.lines.count - 2))
        end
        ranges
      end
    end

    # A helper to return the full text of a file
    # @private
    def full_file(location)
      File.read(location.first)
    end

    # source_helper and valid_expression? are from the method_source gem
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


    # (see #source_helper)
    def valid_expression?(code)
      RubyParser.new.parse(code)
    rescue Racc::ParseError, SyntaxError
      false
    else
      true
    end

  end
end
