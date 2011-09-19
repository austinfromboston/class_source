require 'method_source'
require 'tempfile'
require 'yaml'
require 'class_source/declarations'
require 'class_source/steno'
require 'class_source/discovery'
require 'class_source/method_detailer'
require 'class_source/index'
require 'class_source/method_index'

module ClassSource
  def self.extended(base)
    base.instance_eval do
      extend Steno
      extend Discovery
      extend MethodDetailer
    end
  end

  def __source__
    Index.new(self)
  end
end

