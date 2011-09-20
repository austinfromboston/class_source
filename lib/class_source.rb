require 'method_source'
require 'tempfile'
require 'yaml'

require 'class_source/declarations'
require 'class_source/index'
require 'class_source/method_index'
require 'class_source/locator'
require 'class_source/guesser'
require 'class_source/collator'

module ClassSource
  def __source__(options={})
    Index.new(self, options)
  end
end

