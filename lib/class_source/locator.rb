require 'tempfile'
require 'yaml'

module ClassSource
  # A helper class responsible for tracing the evaluation of files to discover class declarations points
  class Locator
    def initialize(target_class, options={})
      @klass = target_class
      @options=options
    end

    # @return [Array] An array of [file_path, line_number] tuples describing where the class was declared.
    def to_a
      source_locations
    end

    # @return [ClassSource::MethodIndex] A pointer to the method index for tracking down files.
    # @private
    def methods
      MethodIndex.new(@klass)
    end

    # @return [Array] An array of file paths where the class was declared.
    def files(options={})
      @source_files ||= methods.locations.map(&:first).uniq
      return @source_files + [@options[:file]] if @options[:file]
      @source_files
    end

    # @return (see #to_a)
    # @private
    def source_locations(options={})
      return @locations if @locations
      evaluate_code_in_a_fork(options)
      @locations = if !Declarations[@klass.name].nil?
        Declarations[@klass.name].uniq 
      else
        Scanner.new(@klass, files).locations || [] 
      end
    end

    # @private
    def evaluate_code_in_a_fork(options)
      t = Tempfile.new('class_creation_events')
      fork do
        declarations = files(options).inject({}) do |declarations, source_file|
          trace_declarations(source_file, declarations)
        end
        YAML.dump(declarations, t)
      end
      Process.wait
      t.close
      Declarations.save YAML.load_file(t.path)
    end

    # Traces the evaluation of a file looking for class declarations
    # @private
    def trace_declarations(source_file, declarations)
      set_trace_func lambda { |event, file, line, id, binding, classname|
        defined_class = standard_class_declared(event, binding) || dynamic_class_declared(id, classname, file, line)
        break unless defined_class
        defined_class_name = defined_class.is_a?(String) ? defined_class : defined_class.name
        declarations[defined_class_name] ||= []
        declarations[defined_class_name] << [ file, line ]
      }
      silence_warnings { load source_file }
      declarations
    end

    # A heuristic for seeing that a class has been declared dynamically (e.g. using Class.new)
    # @private
    def dynamic_class_declared(id, classname, file, line)
      return unless id == :new && classname == Class 
      File.read(file).lines.to_a[line-1][/[A-Z][\w_:]*/, 0]
    end

    # A fast way to spot a normal class declaration (e.g. class MyNewClass)
    # @private
    def standard_class_declared(event, binding)
      return unless event == 'class'
      event_class = eval( "Module.nesting", binding )
      event_class.first
    end

    # Need one of these, re-evaluating code is a noisy business
    # @private
    def silence_warnings
      old_verbose, $VERBOSE = $VERBOSE, nil
      yield
    ensure
      $VERBOSE = old_verbose
    end
  end
end
