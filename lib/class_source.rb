require 'class_source/declarations'
require 'class_source/index'
require 'class_source/method_index'
require 'class_source/class_method_index'
require 'class_source/locator'
require 'class_source/scanner'
require 'class_source/collator'

# extend your class with ClassSource in order to inspect its source
module ClassSource
  # Returns a proxy for inspecting the source of a class
  # To view the source as a string, use 
  #     ExampleClass.__source__.to_s
  #
  # To view the source as a hash of file/line locations and strings, use
  #     ExampleClass.__source__.all
  #
  # @return[ClassSource::Index] an index of all source code used to construct the class
  def __source__(options={})
    Index.new(self, options)
  end
end

