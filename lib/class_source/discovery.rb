module ClassSource
  module Discovery
    def full_file(location)
      File.read(location.first)
    end

    def guess_source_location
      return if source_files.empty?
      @locations = source_files.map do |file|
        [file, find_module_name(File.read(file))]
      end.select { |result| !result.last.nil? }
    end

    def find_module_name(text)
      submodule_name = name.split("::").last
      text.lines.each.with_index do |line, index|
        return index + 1 if line.match /\b#{submodule_name}\b/
      end
      nil
    end
  end
end
