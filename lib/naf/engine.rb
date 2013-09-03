require 'rubygems'
require 'will_paginate'
require 'facter'
require 'jquery-rails'
require 'log4r_remote_syslog_outputter'
require 'partitioned'
require 'd3-rails'

module Naf
  class Engine < ::Rails::Engine
    isolate_namespace Naf
    engine_name "naf"

    initializer "dependencies" do
      require 'partitioned'
      require 'log4r_remote_syslog_outputter'
    end
  end
end
