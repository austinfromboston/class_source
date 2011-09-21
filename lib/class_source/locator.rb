require 'tempfile'
require 'yaml'

module ClassSource
  class Locator
    def initialize(target_class, options={})
      @klass = target_class
      @options=options
    end

    def to_a
      source_locations
    end

    def methods
      MethodIndex.new(@klass)
    end

    def files(options={})
      @source_files ||= methods.locations.map(&:first).uniq
      return @source_files + [@options[:file]] if @options[:file]
      @source_files
    end

    def source_locations(options={})
      return @locations if @locations
      t = Tempfile.new('class_creation_events')
      fork do
        declarations = files(options).inject({}) do |declarations, source_file|
          trace_declarations(source_file, declarations)
        end
        YAML.dump(declarations, t)
      end
      Process.wait
      Declarations.save YAML.load_file(t.path)
      t.close
      @locations = if !Declarations[@klass.name].nil?
        Declarations[@klass.name].uniq 
      else
        Guesser.new(@klass, files).locations || [] 
      end
    end

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

    def dynamic_class_declared(id, classname, file, line)
      return unless id == :new && classname == Class 
      File.read(file).lines.to_a[line-1][/[A-Z][\w_:]*/, 0]
    end

    def standard_class_declared(event, binding)
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
  end
end
