module ClassSource
  class Guesser
    def initialize(klass, source_files)
      @source_files = source_files
      @klass = klass
    end

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
