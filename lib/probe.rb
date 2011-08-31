require 'rubygems'
require 'method_source'

class Probe
  attr_reader :files, :classes

  def initialize(path)
    @files = []
    @files << File.new(path)
    load_classes
  end

  def load_classes
    @classes = []
    @methods = []
    @files.each do |f|
      load f.path
      class_matches = f.read.scan /class\s([A-Z]+[A-Za-z0-9]*)/
      @classes += class_matches.map { |match| Probe::ClassInfo.new(match[0], :source => f.path) }
    end
  end

  def methods
    classes.map(&:methods).flatten
  end

  def cleanup!
    @classes.each do |klass|
      Object.send(:remove_const, klass.name.to_sym) if Object.const_defined?(klass.name.to_sym)
    end
  end



  class ClassInfo < BasicObject
    attr_reader :name, :source
    def initialize(name, options={})
      @name = name
      @source = options[:source]
    end

    def methods
      klass = ::Object.const_get(name)
      method_names = klass.instance_methods - (klass.ancestors - [klass]).map(&:instance_methods).flatten
      method_names.map { |name| klass.instance_method(name) }
    end
  end

  class MethodInfo < BasicObject
    attr_reader :name, :length
    def initialize(name)
      @name = name
    end
  end

end
