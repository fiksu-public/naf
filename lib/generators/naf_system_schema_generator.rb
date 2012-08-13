require 'rails/generators'
require 'rails/generators/migration'
require File.expand_path(File.dirname(__FILE__) +  '/naf_generator_helper')

class NafSystemSchemaGenerator < Rails::Generators::Base
  include Rails::Generators::Migration
  include NafGeneratorHelper

  source_root File.expand_path("../templates", __FILE__)
  argument :schema_name, :type => :string, :default => default_postgres_schema

  def self.next_migration_number(path)
    Time.now.utc.strftime("%Y%m%d%H%M%S")
  end
  
  def create_migration
    migration_template('naf_schema.rb', 'db/migrate/create_job_system.rb')
  end
end
