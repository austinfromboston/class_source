require 'spec_helper'

describe ClassSource do
  after { test_unload_all }

  describe "for a simple class with only an initializer" do
    before do
      test_load 'SimpleClass'
    end
    it "knows the unique methods of the class" do
      SimpleClass.__source__.methods.unique.should == [:initialize]
    end

    it "knows the method location for each of the unique methods of the class" do
      SimpleClass.__source__.methods.locations.should == [[fixtures_path(:simple_class), 4]]
    end

    it "can pinpoint the opening of a simple class" do
      SimpleClass.__source__.locations.should == [[fixtures_path(:simple_class), 3]]
    end

    it "can return the full source of a simple class" do
      SimpleClass.__source__.should == File.read(fixtures_path(:simple_class)).lines.to_a[2..-1].join("")
    end
  end

  describe "for a class with public, private and protected methods" do
    before { test_load 'ProtectedMethodClass' }

    it "knows the unique methods of the class" do
      ProtectedMethodClass.__source__.methods.unique.should =~ [:initialize, :talk, :think, :whisper]
    end

    it "knows the method location for each of the unique methods of the class" do
      ProtectedMethodClass.__source__.methods.locations.should =~ [
        [fixtures_path(:protected_method_class), 2],
        [fixtures_path(:protected_method_class), 6],
        [fixtures_path(:protected_method_class), 11],
        [fixtures_path(:protected_method_class), 16]
      ]
    end

    it "can pinpoint the opening" do
      ProtectedMethodClass.__source__.locations.should == [[fixtures_path(:protected_method_class), 1]]
    end

    it "can return the full source" do
      ProtectedMethodClass.__source__.should == File.read(fixtures_path(:protected_method_class)).lines.to_a[0..-1].join("")
    end
  end

  describe "for a subclass of a user class" do
    before { test_load 'ProtectedMethodClass', 'SubClass' }

    it "knows the unique methods of the class" do
      SubClass.__source__.methods.unique.should =~ [:talk, :think]
    end

    it "knows the method location for each of the unique methods of the class" do
      SubClass.__source__.methods.locations.should =~ [
        [fixtures_path(:sub_class), 2],
        [fixtures_path(:sub_class), 6]
      ]
    end

    it "can pinpoint the opening" do
      SubClass.__source__.locations.should == [[fixtures_path(:sub_class), 1]]
    end

    it "can return the full source" do
      SubClass.__source__.should == File.read(fixtures_path(:sub_class)).lines.to_a[0..-1].join("")
    end
  end

  describe "for a nested class" do
    before { test_load 'OuterClass' }
    it "can return the full source" do
      OuterClass::NestedClass.__source__.should == File.read(fixtures_path(:outer_class)).lines.to_a[12..16].join("")
    end
  end

  describe "for a class with no unique methods" do
    before { test_load 'NoMethodsClass' }
    it "can return the full source if you pass a source file" do
      NoMethodsClass.__source__(:file => fixtures_path(:no_methods_class)).should == File.read(fixtures_path(:no_methods_class)).lines.to_a[0..4].join("")
    end
    describe "for a nested class with no unique methods" do
      it "can return the full source" do
        NoMethodsClass::NestedClass.__source__(:file => fixtures_path(:no_methods_class)).should == File.read(fixtures_path(:no_methods_class)).lines.to_a[1..3].join("")
      end
    end
  end

  describe "for an outer class" do
    before { test_load 'OuterClass' }
    it "can return the full source" do
      OuterClass.__source__.should == File.read(fixtures_path(:outer_class)).lines.to_a[0..-1].join("")
    end

    it "can also return the source minus any nested classes" do
      source_lines = File.read(fixtures_path(:outer_class)).lines.to_a
      non_nested_lines = (source_lines[0..3] + source_lines[8..11] + source_lines[17..-1]).join("")
      OuterClass.__source__.to_s(:include_nested => false).should == non_nested_lines
    end
  end

  describe "for dynamically defined classes" do
    before do
      test_load 'DynamicClass'
    end

    it "should have a single source location" do
      DynamicClass.__source__.should have(1).locations
    end

    it "can return the full source" do
      DynamicClass.__source__.should == File.read(fixtures_path(:dynamic_class)).lines.to_a[0..4].join("")
    end

    it "can return the source for a class named later in the file" do
      LateNamedDynamicClass.send :extend, ClassSource
      LateNamedDynamicClass.__source__.should == File.read(fixtures_path(:dynamic_class)).lines.to_a[11]
    end

    describe "with no methods" do
      it "knows the source" do
        MethodlessDynamicClass.send :extend, ClassSource
        MethodlessDynamicClass.__source__.should == "MethodlessDynamicClass = Class.new\n"
      end
    end
  end

  describe "for duplicated classes" do
    before { test_load 'DuplicatedClass' }
    it "should point to the duplication point" do
      DuplicateClass.__source__.locations.should == [
        [fixtures_path(:duplicated_class), 5]
      ]
    end
  end

  describe "for cloned classes" do
    before { test_load 'ClonedClass' }
    it "should point to the cloning point" do
      CloneClass.__source__.locations.should == [
        [fixtures_path(:cloned_class), 5]
      ]
    end
  end

  describe "for classes defined within eval" do 
    before { test_load 'EvalClass' }
    it "should point to the evaluation point" do
      EvalClass.__source__.locations.should == [
        [fixtures_path(:eval_class), 11]
      ]
    end
  end 

  describe "for classes that are reopened in separate files" do
    before { test_load 'ReOpenedClass' }
    it "should have more than one source file" do
      ReOpenedClass.__source__.files.length.should == 2
    end

    it "should have more than one source location" do
      ReOpenedClass.__source__.locations.length.should == 2
    end

    it "should have the full source in its source" do
      ReOpenedClass.__source__.all.should == {
        [fixtures_path(:re_opened_class), 3] => File.read(fixtures_path(:re_opened_class)).lines.to_a[2..-1].join(""), 
        [fixtures_path(:re_opened_class_2), 1] => File.read(fixtures_path(:re_opened_class_2))
      }
    end

    it "should be able to display without nested classes if needed" do
      reopened_source = File.read(fixtures_path(:re_opened_class)).lines.to_a
      reopened_source_2 = File.read(fixtures_path(:re_opened_class_2)).lines.to_a
      ReOpenedClass.__source__.all(:include_nested => false).should == {
        [fixtures_path(:re_opened_class), 3] => (reopened_source[2..6] + reopened_source[15..-1]).join(""),
        [fixtures_path(:re_opened_class_2), 1] => (reopened_source_2[0..4] + reopened_source_2[10..-1]).join("")
      }
    end
  end

  describe "for a nested class that is reopened within the parent" do 
    before { test_load 'ReOpenedClass' }
    it "should have more than one source location" do
      ReOpenedClass::NestedClass.__source__.all.should == {
        [fixtures_path(:re_opened_class), 8] => File.read(fixtures_path(:re_opened_class)).lines.to_a[7..10].join(""), 
        [fixtures_path(:re_opened_class), 12] => File.read(fixtures_path(:re_opened_class)).lines.to_a[11..14].join("") 
      }
    end
  end

  describe "for class with only class methods" do
    before do
      test_load 'ClassMethodsClass'
    end
    it "knows the unique class methods of the class" do
      ClassMethodsClass.__source__.class_methods.unique.should == [:simple_method]
    end
    it "can find the source" do
      ClassMethodsClass.__source__.should == File.read(fixtures_path(:class_methods_class)).lines.to_a[0..-1].join("")
    end
  end

  describe "it doesn't cause side effects for class-scoped code" do
    before do
      test_load 'SideEffectClass'
    end

    it "should retain the same values as set" do
      SideEffectClass.should be_active
      SideEffectClass.deactivate!
      SideEffectClass.should_not be_active
      SideEffectClass.__source__.should == File.read(fixtures_path(:side_effect_class)).lines.to_a[0..-1].join("")
      SideEffectClass.should_not be_active
    end
  end

end
