$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "naf/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "naf"
  s.version     = Naf::VERSION
  s.license     = 'New BSD License'
  s.date        = '2012-08-21'
  s.summary     = "Creates infrastructure for a customizable and robust Postgres-backed script scheduling/running"
  s.description = "Infrastructure includes abstractions for machines, runners, affinities, easily importable to any Rails app"
  s.authors     = ["Keith Gabryelski", "Nathaniel Lim"]
  s.email       = ['keith@fiksu.com', 'nlim@fiksu.com']
  s.files       = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.homepage    = 'http://github.com/fiksu/naf'

  s.add_dependency "rails", ">= 3.2"
  s.add_dependency "jquery-rails"
  s.add_development_dependency "pg"
  s.add_dependency "rspec-rails"
  s.add_dependency "foreigner"
end
