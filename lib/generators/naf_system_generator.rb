require File.expand_path(File.dirname(__FILE__) +  '/naf_generator_helper')
require 'rails/generators'

class NafSystemGenerator < Rails::Generators::Base
  include NafGeneratorHelper

  source_root File.expand_path("../templates", __FILE__)

  argument :schema_name, :type => :string, :default => default_postgres_schema

  def add_job_system_intializer
    path = "#{Rails.root}/config/initializers/job_system_initializer.rb"
    if File.exists?(path)
      puts "Skipping config/initializers/job_system_initializer.rb creation, as file already exists!"
    else
      puts "Adding job system initializer (config/initializers/job_system_initializer.rb)..."
      template 'job_system_initializer.rb', path
    end
  end

  def add_job_system_config
    path = "#{Rails.root}/config/job_system_config.yml"
    if File.exists?(path)
      puts "Skipping config/job_system_config.yml creation, as file already exists!"
    else
      puts "Adding job_system_config.yml initializer (config/job_system_config.yml)..."
      template 'job_system_config.yml', path
    end
  end

  def mount_engine
    puts "Mounting Naf::Engine at \"/job_system\" in config/routes.rb..."
    insert_into_file("#{Rails.root}/config/routes.rb", :before => /$\s*end\n/) do
      %Q{\n  mount Naf::Engine, :at => "/job_system"\n}
    end
  end


end
