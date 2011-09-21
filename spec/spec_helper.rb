require 'rubygems'
SOURCE_PATH=File.expand_path(File.dirname(__FILE__), '../lib')
$LOAD_PATH << SOURCE_PATH
require 'class_source'

RSpec.configure do
  def spec_path
    @path ||= File.expand_path(File.dirname(__FILE__))
  end

  def fixtures_path(file_name)
    "#{SOURCE_PATH}/fixtures/#{file_name}.rb"
  end

  def test_load(*args)
    name = args.shift
    file_name = name.to_s.gsub(/([A-Z])/) { |match| "_" + match.downcase }.slice(1..-1)
    raise "can't find #{fixtures_path(file_name)}" unless File.exist?(fixtures_path(file_name))

    @loaded_fixtures ||= []
    @loaded_fixtures << name
    existing_classes = Object.constants
    load fixtures_path(file_name)
    new_classes = Object.constants - existing_classes - [name.to_sym]
    @loaded_fixtures += new_classes.map &:to_s
    allow_source_inspection(name)

    test_load(*args) unless args.empty?
    new_classes.each { |new_name| allow_source_inspection(new_name) }
  end

  def allow_source_inspection(name, nesting = Object)
    klass = nesting.const_get(name.to_sym)

    klass.send :extend, ClassSource
    klass.constants.select { |kc| klass.const_get(kc).is_a?(Class) }.each do |nested_class|
      allow_source_inspection nested_class, klass
    end
  end

  def test_unload_all
    @loaded_fixtures.each do |klass_name|
      Object.send :remove_const, klass_name if Object.const_defined?(klass_name)
    end
  end

end
