# Configure Rails Environment
ENV["RAILS_ENV"] = "test"

# What will our dummy Rails app be? 
require File.expand_path("../dummy/config/environment.rb",  __FILE__)

require 'rspec/rails'
require 'rspec/autorun'
require 'factory_girl'


ENGINE_RAILS_ROOT = File.join(File.dirname(__FILE__), '../')

# Require supporting files in spec/support
Dir[File.join(ENGINE_RAILS_ROOT, "spec/support/**/*.rb")].each {|f| require f }

RSpec.configure do |config|
  config.use_transactional_fixtures = true
  config.include Naf::Engine.routes.url_helpers
  config.infer_base_class_for_anonymous_controllers = true
  config.include EngineRouting, :type => :controller
end

FactoryGirl.find_definitions

# Create the DB Seed Records via Factories
affinities = [:normal_affinity, :canary_affinity, :perennial_affinity]
classifications = [:location_affinity_classification, :purpose_affinity_classification, :application_affinity_classification]
restrictions = [:no_restriction, :one_at_a_time_restriction, :one_per_machine_restriction]

(affinities + classifications + restrictions).each do |seed|
  FactoryGirl.create(seed)
end
