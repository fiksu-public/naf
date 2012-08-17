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
    path = "#{Rails.root}/config/job_system_schema_config.yml"
    if File.exists?(path)
      puts "Skipping config/job_system_schema_config.yml creation, as file already exists!"
    else
      puts "Adding job_system_schema_config.yml initializer (config/job_system_schema_config.yml)..."
      template 'job_system_schema_config.yml', path
    end
  end

  def mount_engine
    puts "Mounting Naf::Engine at \"/job_system\" in config/routes.rb..."
    insert_into_file("#{Rails.root}/config/routes.rb", :after => /routes.draw.do\n/) do
      %Q{ mount Naf::Engine, :at => "/job_system"\n}
    end
  end

  def add_assets
    path = "#{Rails.root}/app/assets/javascripts/application.js"
    if File.exists?(path)
      if File.readlines(path).grep(/\/\/= require naf/).any?
        puts "Naf Javascript files already required"
      else
        puts "Adding Naf Javascript files to the asset pipeline"
        insert_into_file(path, :after => /\/\/= require jquery\s*\n/) do
          %Q{//= require naf\n}
        end
      end
    end
  
    path = "#{Rails.root}/app/assets/stylesheets/application.css"
    if File.exists?(path)
      if File.readlines(path).grep(/\*= require naf/).any?
        puts "Naf Stylesheet files already required"        
      else
        puts "Adding Naf Stylesheet files to the asset pipeline"
        insert_into_file(path, :after => /\*= require_self\s*\n/ ) do
          %Q{*= require naf\n}
        end
      end
    end
  end



end
