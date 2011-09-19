method_name = "simple_method"
class_name = "EvalClass"

code = <<-CODE 
  class #{class_name}
    def #{method_name}
    end
  end
CODE

eval code, binding, __FILE__, __LINE__ 
