require 'rails/generators'
require 'rails/generators/migration'

class NafSystemGenerator < Rails::Generators::Base

  include Rails::Generators::Migration

  source_root File.expand_path("../templates", __FILE__)

  argument :schema_name, :type => :string, :default => Rails.application.class.parent_name.split(/([[:upper:]][[:lower:]]*)/).delete_if(&:empty?).map(&:downcase).join('_') + '_job_system'

  def add_job_system_intializer
    path = "#{Rails.root}/config/initializers/job_system_schema_initializer.rb"
    if File.exists?(path)
      puts "Skipping config/initializers/job_system_schema_initializer.rb creation, as file already exists!"
    else
      puts "Adding job system initializer (config/initializers/job_system_schema_initializer.rb)..."
      template 'job_system_schema_initializer.rb', path
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

  def add_migrations_extension
    path = "#{Rails.root}/config/initializers/extensions_migration.rb"
    if File.exists?(path)
      puts "Skipping config/initializers/extensions_migration.rb creation, as file already exists!"
    else
      puts "Adding migration extension for executing raw sql (config/initializers/extensions_migration.rb)..."
      template 'extensions_migration.rb', path
    end
  end

  def self.next_migration_number(path)
    Time.now.utc.strftime("%Y%m%d%H%M%S")
  end

  def create_migration
    migration_template('naf_schema.rb', 'db/migrate/create_job_system.rb')
  end

  def mount_engine
    puts "Mounting Naf::Engine at \"/job_system\" in config/routes.rb..."
    insert_into_file("#{Rails.root}/config/routes.rb", :after => /routes.draw.do\n/) do
      %Q{ mount Naf::Engine, :at => "/job_system"\n}
    end
  end



end
