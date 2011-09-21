$:.push File.expand_path("../lib", __FILE__)
require "class_source/version"
Gem::Specification.new do |s|
  s.name    = "class_source"
  s.version = ClassSource::VERSION
  s.authors = ["Austin Putman, austingfromboston"]
  s.email   = ["austin@rawfingertips.com"]

  s.rubyforge_project = "class_source"

  s.summary     = "See where your classes are defined"
  s.description = "Expose source files and full source code for each class via a simple API"
  s.homepage    = "http://github.com/austinfromboston/class_source"
  s.files       = Dir.glob("lib/**/*.rb")
  s.test_files  = Dir.glob("spec/**/*.rb")
  s.require_paths = ["lib"]

  s.add_development_dependency "rspec"
  s.add_runtime_dependency "ruby_parser"
  s.license = 'MIT'
end
