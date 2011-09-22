# @markup markdown
# @title ClassSource

Getting Started
===============

Installation
------------

ClassSource is distributed via rubygems.

    gem install class_source


Inspecting the Source of a Class
--------------------------------

First you'll want to extend your class with ClassSource

    MyClass.send :extend, ClassSource

Now you can get the source of your class.

    MyClass.__source__.to_s

    # => "class MyClass\n  def method1\n    puts "hambone"\n  end\nend"

You may want to know where the source was defined.  This data will be returned as an array of [file, line_number] pairs, much like the 
results of Ruby 1.9's UnboundMethod#source_location method.

    MyClass.__source__.locations

    # => [["lib/my_class.rb", 12], ["lib/monkey_path.rb", 14]]

And at times you may want source file data indexed by location.

    MyClass.__source__.all

    # => {["lib/my_class.rb", 12] => "class MyClass\nend\n", ["lib/monkey_patch.rb", 14] => "class MyClass\n  def method1\n  puts "hambone"\n  end\nend"}


Caveats
-------

ClassSource is an 80% solution which handles common cases.  It is designed to be non-invasive and permit the inspection of a runtime constructed prior
to the introduction of ClassSource.  It doesn't override 'require' or 'load'.  It is implemented in pure Ruby.

Credits
-------

ClassSource is inspired by and in some cases supplemented by code originally used in MethodSource by John Mair (banisterfiend).  Thank you.
