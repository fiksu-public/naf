# Configure Rails Environment
ENV["RAILS_ENV"] ||= "test"

# What will our dummy Rails app be?
require File.expand_path("../dummy/config/environment.rb",  __FILE__)

require 'rspec/rails'
require 'factory_girl'

ENGINE_RAILS_ROOT = File.join(File.dirname(__FILE__), '../')

# Require supporting files in spec/support
Dir[File.join(ENGINE_RAILS_ROOT, "spec/support/**/*.rb")].each {|f| require f }

RSpec.configure do |config|
  config.use_transactional_fixtures = true
  config.include Naf::Engine.routes.url_helpers
  config.infer_base_class_for_anonymous_controllers = true
  config.include EngineRouting, type: :controller

  # rspec-rails 3 will no longer automatically infer an example group's spec type
  # from the file location. You can explicitly opt-in to the feature using this
  # config option.
  # To explicitly tag specs without using automatic inference, set the `:type`
  # metadata manually:
  #
  #     describe ThingsController, :type => :controller do
  #       # Equivalent to being in spec/controllers
  #     end
  config.infer_spec_type_from_file_location!
end

FactoryGirl.find_definitions

# Create the DB Seed Records via Factories
affinities = [:normal_affinity, :canary_affinity, :perennial_affinity]
classifications = [:location_affinity_classification, :purpose_affinity_classification, :application_affinity_classification]
restrictions = [:no_limit, :limited_per_machine, :limited_per_all_machines]

(affinities + classifications + restrictions).each do |seed|
  FactoryGirl.create(seed)
end
