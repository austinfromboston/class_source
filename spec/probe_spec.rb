require 'spec_helper'

describe Probe do
  before do
    @probe = Probe.new(fixtures_path(:example_code))
  end
  after do
    @probe.cleanup!
  end

  it "takes a path as an argument" do
    p = Probe.new(fixtures_path(:example_code))
    p.files.length.should == 1
    p.files.first.should be_a(File)
    p.files.first.path.should == fixtures_path(:example_code)
  end

  it "can clean up the namespace" do
    Object.const_defined?(:Car).should be_true
    @probe.cleanup!
    Object.const_defined?(:Car).should_not be_true
  end

  it "can safely clean up nested namespaces" do
    p1 = Probe.new(fixtures_path(:nested_example))
    p2 = Probe.new(fixtures_path(:unnested_child))
    
    Object.const_defined?(:ParentClass).should be_true
    Object.const_defined?(:ChildClass).should be_true
    ParentClass.const_defined?(:ChildClass).should be_true
    p1.cleanup!
    Object.const_defined?(:ChildClass).should be_true
    Object.const_defined?(:ParentClass).should_not be_true
    p2.cleanup!
  end



  describe "#classes" do

    it "counts the number of classes in the file" do
      @probe.classes.first.name.should == 'Car'
      @probe.classes.length.should == 1
    end

    it "records the source file on the classinfo" do
      @probe.classes.first.source.should == fixtures_path(:example_code)
    end

    it "knows how long the class is as a sum of its method lengths"
    it "includes the size of constants on the class"
  end

  describe "#methods" do
    it "counts the methods" do
      @probe.methods.length.should == 2
      @probe.methods.map(&:name).should =~ ['initialize', 'go']
    end

    it "knows how long each method is" do
      @probe.methods.first.source.length.should == 3
      @probe.methods[1].source.length.should == 4
    end

    it "includes private methods"
    it "includes method comments in the length"
    it "includes class methods"



  end

  it "can read a folder recursively"
end

