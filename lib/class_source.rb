require 'method_source'
require 'tempfile'
require 'yaml'

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
  end

  def source(options = {})
    sources(options).values.join("") unless sources(options).empty?
    # return full_source unless options[:include_nested] == false

    # full_source.lines.to_a.select.with_index do |line, index|
    #   nested_class_line_ranges.all? { |range| !range.include?(index) }
    # end.join("")
  end

  def sources(options = {})
    full_sources = source_locations(options).inject({}) do |results, location|
      results[ location ] = MethodSource.source_helper(location)
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


  def source_locations(options={})
    return @locations if @locations
    t = Tempfile.new('class_creation_events')
    fork do
      declarations = {}
      source_files(options).each do |source_file|
        searched_class = self
        # Object.send :remove_const, self.name.split("::").first
        set_trace_func lambda { |event, file, line, id, binding, classname|
          break unless file == source_file
          # puts({event:event, file:file, line:line, id:id, binding:binding, classname:classname}.inspect)
          defined_class = standard_class_def(event, binding) || dynamic_class_def(id, classname, file, line)
          break unless defined_class
          defined_class_name = defined_class.is_a?(String) ? defined_class : defined_class.name
          # @locations << [ file, line ] if standard_class_def(event, binding) || dynamic_class_def(id, classname, file, line)
          declarations[defined_class_name] ||= []
          declarations[defined_class_name] << [ file, line ]
        }
        silence_warnings { load source_file }
      end
      YAML.dump(declarations, t)
    end
    Process.wait
    save_declarations YAML.load_file(t.path)
    t.close
    return guess_source_location || [] if Declarations[self.name].nil? || Declarations[self.name].empty?
    @locations = Declarations[self.name].uniq 
  end

  def save_declarations(declarations)
    declarations.each do |klass_name, locations|
      Declarations.add(klass_name, locations)
    end
  end

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

  def dynamic_class_def(id, classname, file, line)
    return unless id == :new && classname == Class 
    File.read(file).lines.to_a[line-1][/[A-Z][\w_:]*/, 0] #.match(/\b#{self.name.split('::').last}\b/)
  end

  def standard_class_def(event, binding)
    return unless event == 'class'
    event_class = eval( "Module.nesting", binding )
    event_class.first
  end

  def silence_warnings
    old_verbose, $VERBOSE = $VERBOSE, nil
    yield
  ensure
    $VERBOSE = old_verbose
  end

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

  def nested_class_line_ranges
    nested_classes = constants.select { |c| const_get(c).is_a?(Class) }.map {|c| const_get(c) }
    return @nested_class_ranges if @nested_class_ranges
    @nested_class_ranges = {}
    nested_classes.each do |klass| 
      # (klass.source_location.last-1)..(klass.source_location.last + klass.source.lines.count - 2)
      klass.sources.each do |(file, line), source| 
        @nested_class_ranges[file] ||= []
        @nested_class_ranges[file] << ((line - 1)..(line + source.lines.count - 2))
      end
    end

    @nested_class_ranges
  end

end

