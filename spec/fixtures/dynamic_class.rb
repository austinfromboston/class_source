DynamicClass = Class.new do
  def example_method

  end
end

class_to_be_named_later = Class.new do
  def example_method
  end
end

LateNamedDynamicClass = class_to_be_named_later
MethodlessDynamicClass = Class.new

