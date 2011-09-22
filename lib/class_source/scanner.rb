module ClassSource
  # A helper class for scanning files looking for potential class declarations
  class Scanner
    def initialize(klass, source_files)
      @source_files = source_files
      @klass = klass
    end

    # @return [Array] An array of [file_name, line_number] tuples where the classes name was detected
    def locations
      return if @source_files.empty?
      @source_files.map do |file|
        [file, find_module_name(File.read(file))]
      end.select { |result| !result.last.nil? }
    end

    private

    def find_module_name(text)
      submodule_name = @klass.name.split("::").last
      text.lines.each.with_index do |line, index|
        return index + 1 if line.match /\b#{submodule_name}\b/
      end
      nil
    end
  end
end
