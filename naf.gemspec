$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "naf/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "naf"
  s.version     = Naf::VERSION
  s.license     = 'New BSD License'
  s.date        = '2014-02-26'
  s.summary     = "Creates infrastructure for a customizable and robust Postgres-backed script scheduling/running"
  s.description = "A cloud based distributed cron, application framework and operations console. Naf works as a distributed script running " +
                  "system that provides scheduling, logging, alarming, machine redundancy, and the ability to set constraint during script execution"
  s.authors     = ["Keith Gabryelski", "Leonardo Meira", "Nathaniel Lim", "Aleksandr Dembskiy"]
  s.email       = ['keith@fiksu.com', 'lmeira@fiksu.com']
  s.files       = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.homepage    = 'http://github.com/fiksu/naf'

  s.add_dependency "rails", ">= 3.2"
  s.add_dependency "partitioned"
  s.add_dependency "log4r_remote_syslog_outputter", ">= 0.0.1"
  s.add_dependency "jquery-rails"
  s.add_dependency 'will_paginate'
  s.add_dependency 'facter'
  s.add_development_dependency "pg"
  s.add_development_dependency "rspec-rails"
  s.add_development_dependency "factory_girl_rails", "~> 4.0.0"
  s.add_development_dependency 'awesome_print'

  s.executables   = ["naf"]
end
