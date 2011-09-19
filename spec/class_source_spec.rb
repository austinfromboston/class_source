require 'spec_helper'

describe ClassSource do
  after { test_unload_all }

  describe "for a simple class with only an initializer" do
    before do
      test_load 'SimpleClass'
    end
    it "knows the unique methods of the class" do
      SimpleClass.unique_methods.should == [:initialize]
    end

    it "knows the method location for each of the unique methods of the class" do
      SimpleClass.method_locations.should == [[fixtures_path(:simple_class), 4]]
    end

    it "can pinpoint the opening of a simple class" do
      SimpleClass.source_locations.should == [["#{PROBE_PATH}/fixtures/simple_class.rb", 3]]
    end

    it "can return the full source of a simple class" do
      SimpleClass.source.should == File.read(fixtures_path(:simple_class)).lines.to_a[2..-1].join("")
    end
  end

  describe "for a class with public, private and protected methods" do
    before { test_load 'ProtectedMethodClass' }

    it "knows the unique methods of the class" do
      ProtectedMethodClass.unique_methods.should =~ [:initialize, :talk, :think, :whisper]
    end

    it "knows the method location for each of the unique methods of the class" do
      ProtectedMethodClass.method_locations.should =~ [
        [fixtures_path(:protected_method_class), 2],
        [fixtures_path(:protected_method_class), 6],
        [fixtures_path(:protected_method_class), 11],
        [fixtures_path(:protected_method_class), 16]
      ]
    end

    it "can pinpoint the opening" do
      ProtectedMethodClass.source_locations.should == [[fixtures_path(:protected_method_class), 1]]
    end

    it "can return the full source" do
      ProtectedMethodClass.source.should == File.read(fixtures_path(:protected_method_class)).lines.to_a[0..-1].join("")
    end
  end

  describe "for a subclass of a user class" do
    before { test_load 'ProtectedMethodClass', 'SubClass' }

    it "knows the unique methods of the class" do
      SubClass.unique_methods.should =~ [:talk, :think]
    end

    it "knows the method location for each of the unique methods of the class" do
      SubClass.method_locations.should =~ [
        [fixtures_path(:sub_class), 2],
        [fixtures_path(:sub_class), 6]
      ]
    end

    it "can pinpoint the opening" do
      SubClass.source_locations.should == [[fixtures_path(:sub_class), 1]]
    end

    it "can return the full source" do
      SubClass.source.should == File.read(fixtures_path(:sub_class)).lines.to_a[0..-1].join("")
    end
  end

  describe "for a nested class" do
    before { test_load 'OuterClass' }
    it "can return the full source" do
      OuterClass::NestedClass.source.should == File.read(fixtures_path(:outer_class)).lines.to_a[12..16].join("")
    end
  end

  describe "for a class with no unique methods" do
    before { test_load 'NoMethodsClass' }
    it "can return the full source if you pass a source file" do
      NoMethodsClass.source(:file => fixtures_path(:no_methods_class)).should == File.read(fixtures_path(:no_methods_class)).lines.to_a[0..4].join("")
    end
    describe "for a nested class with no unique methods" do
      it "can return the full source" do
        NoMethodsClass::NestedClass.source(:file => fixtures_path(:no_methods_class)).should == File.read(fixtures_path(:no_methods_class)).lines.to_a[1..3].join("")
      end
    end
  end

  describe "for an outer class" do
    before { test_load 'OuterClass' }
    it "can return the full source" do
      OuterClass.source.should == File.read(fixtures_path(:outer_class)).lines.to_a[0..-1].join("")
    end

    it "can also return the source minus any nested classes" do
      source_lines = File.read(fixtures_path(:outer_class)).lines.to_a
      non_nested_lines = (source_lines[0..3] + source_lines[8..11] + source_lines[17..-1]).join("")
      OuterClass.source(:include_nested => false).should == non_nested_lines
    end
  end

  describe "for dynamically defined classes" do
    before do
      test_load 'DynamicClass'
    end

    it "should have a single source location" do
      DynamicClass.should have(1).source_locations
    end

    it "can return the full source" do
      DynamicClass.source.should == File.read(fixtures_path(:dynamic_class)).lines.to_a[0..4].join("")
    end

    it "can return the source for a class named later in the file" do
      LateNamedDynamicClass.send :extend, ClassSource
      LateNamedDynamicClass.source.should == File.read(fixtures_path(:dynamic_class)).lines.to_a[11]
    end

    describe "with no methods" do
      it "knows the source" do
        MethodlessDynamicClass.send :extend, ClassSource
        MethodlessDynamicClass.source.should == "MethodlessDynamicClass = Class.new\n"
      end
    end


  end
  describe "for duplicated classes" do
    it "--"
  end
  describe "for classes defined within eval" do 
    it "--"
  end 

  describe "for classes that are reopened in separate files" do
    before { test_load 'ReOpenedClass' }
    it "should have more than one source file" do
      ReOpenedClass.source_files.length.should == 2
    end

    it "should have more than one source location" do
      ReOpenedClass.source_locations.length.should == 2
    end

    it "should have the full source in its source" do
      ReOpenedClass.sources.should == {
        [fixtures_path(:re_opened_class), 3] => File.read(fixtures_path(:re_opened_class)).lines.to_a[2..-1].join(""), 
        [fixtures_path(:re_opened_class_2), 1] => File.read(fixtures_path(:re_opened_class_2))
      }
    end

    it "should be able to display without nested classes if needed" do
      reopened_source = File.read(fixtures_path(:re_opened_class)).lines.to_a
      reopened_source_2 = File.read(fixtures_path(:re_opened_class_2)).lines.to_a
      ReOpenedClass.sources(:include_nested => false).should == {
        [fixtures_path(:re_opened_class), 3] => (reopened_source[2..6] + reopened_source[11..-1]).join(""),
        [fixtures_path(:re_opened_class_2), 1] => (reopened_source_2[0..4] + reopened_source_2[10..-1]).join("")
      }
    end
  end

  describe "for a nested class that is reopened within the parent" do 
    it "--"
  end

  describe "for class with only class methods" do
    before do
      test_load 'ClassMethodsClass'
    end
    it "knows the unique class methods of the class" do
      ClassMethodsClass.unique_class_methods.should == [:simple_method]
    end
    it "can find the source" do
      ClassMethodsClass.source.should == File.read(fixtures_path(:class_methods_class)).lines.to_a[0..-1].join("")
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
      SideEffectClass.source.should == File.read(fixtures_path(:side_effect_class)).lines.to_a[0..-1].join("")
      SideEffectClass.should_not be_active
    end
  end

end
