require 'fileutils'
# Add methods for aliasing and overriding rake tasks                                                                                                                                          
# From: http://metaskills.net/2010/5/26/the-alias_method_chain-of-rake-override-rake-task                                                                                                     
Rake::TaskManager.class_eval do
  def alias_task(fq_name)
    new_name = "#{fq_name}:original"
    @tasks[new_name] = @tasks.delete(fq_name)
  end
end

def alias_task(fq_name)
  Rake.application.alias_task(fq_name)
end

def override_task(*args, &block)
  name, params, deps = Rake.application.resolve_args(args.dup)
  fq_name = Rake.application.instance_variable_get(:@scope).dup.push(name).join(':')
  alias_task(fq_name)
  Rake::Task.define_task(*args, &block)
end



# --------------------------------------------------
# ---------------Custom Rake Tasks for Naf----------
# --------------------------------------------------
namespace :naf do

  namespace :install do
    desc "Custom install of Engine migrations to db/naf/migrate folder"
    override_task :migrations => :environment do

      puts "Copying naf migration files to folder: #{naf_migrations_folder}"
      
      FileUtils.mkdir(naf_folder) unless Dir.exists?(naf_folder)
      FileUtils.mkdir(naf_migrations_folder) unless Dir.exists?(naf_migrations_folder)

      source_folder = "#{Naf::Engine.root}/db/naf/migrate"

      Dir.entries(source_folder).grep(/\.rb/).each do |migration_file|
        file_path = "#{source_folder}/#{migration_file}"
        puts "#{naf_migrations_folder}/#{migration_file}"
        if File.exists?("#{naf_migrations_folder}#{migration_file}")
          puts "\t#{migration_file} already exists, skipping"
        else
          puts "\tCopying #{file_path} => #{naf_migrations_folder}"
          FileUtils.cp(file_path, naf_migrations_folder)
        end
      end

    end
  end

  namespace :db do
    desc "Custom migrate task, connects to correct database, migrations found in db/naf/migrate"
    override_task :migrate => :environment do
      puts "Running naf migrations with db configuration: #{naf_environment}"
      puts naf_migrations
      connect_to_naf_database do
        version = ENV['VERSION'] ?  ENV['VERSION'].to_i : nil
        ActiveRecord::Migrator.migrate(naf_migrations_folder, version )
      end
    end
    
    desc "Perform a rollback on the warehousing database within the data_api schema"
    task :rollback => :environment do
      connect_to_naf_database do
        step = ENV['STEP'] ? ENV['STEP'].to_i : 1
        ActiveRecord::Migrator.rollback(naf_migrations_folder, step)
      end
    end
  end

  desc "Undo all of the naf schema migrations"
  task :schema_rollback => :environment do
    puts "Rolling back all of Naf migrations"
    connect_to_naf_database do
      ActiveRecord::Migrator.migrate(naf_migrations_folder, 0)
    end
  end

  desc "Delete all of the naf schema migrations files that were installed"
  task :remove_migration_files => [:environment, :schema_rollback] do
    naf_migrations.each do |migration| 
      file_path = "#{naf_migrations_folder}#{migration}"
      if File.exists?(file_path)
        puts "Removing migration file: #{migration}"
        File.delete(file_path)
      end
    end

    if Dir.exists?(naf_migrations_folder)
      puts "Removing folder #{naf_migrations_folder}"
      FileUtils.rmdir(naf_migrations_folder)
    end
    if Dir.exists?(naf_folder)
      puts "Removing folder #{naf_folder}"
      FileUtils.rmdir(naf_folder)
    end
  end

  desc "Deletes initalizers, configs that were installed, revert edit to config/routes"
  task :system_teardown => :environment do
    files_to_remove = [
      "config/initializers/job_system_initializer.rb", 
      "config/job_system_config.yml"
    ]
    edit_file_line_regex_hash = { 
      "config/routes.rb" => %r{$  mount Naf::Engine, :at => "/job_system"\s*\n}
    } 
    files_to_remove.each do |file|
      file_path = "#{Rails.root}/#{file}"
      if File.exists?(file_path)
        puts "Removing file: #{file}"
        File.delete(file_path)
      end
    end
    edit_file_line_regex_hash.each do |file, regex|
      puts "Reverting Naf Engine's edits to #{file}"
      file_path = "#{Rails.root}/#{file}"
      gsub_file(file_path, regex, '')
    end
  end

  desc "The master task for completely expunging the installation of the naf Engine"
  task :teardown => [:system_teardown, :remove_migration_files] do
  end

end


# Helper Methods


# Transactions method to connect to the specific database
# you want the naf tables to live in
def connect_to_naf_database
  original = ActiveRecord::Base.remove_connection
  ActiveRecord::Base.establish_connection(naf_environment)
  yield
ensure
  ActiveRecord::Base.establish_connection original
end

# Specifiy the naf environment, the configuration that migrations with run under,
# If the naf_#{Rails.env} configuration exists in in database.yml, choose that, 
# else choose Rails.env
def naf_environment
  naf_environments = ActiveRecord::Base.configurations.keys.select{|env| env == "naf_#{Rails.env}"}
  if naf_environments.any?
    return naf_environments.first
  else
    return Rails.env.to_s
  end
end

# Subsitute matches to a given regex in the given file, with the given string
def gsub_file(path, regexp, *args, &block)
  content = File.read(path).gsub(regexp, *args, &block)
  File.open(path, 'wb') { |file| file.write(content) }
end

def naf_folder
  "#{Rails.root}/db/naf/"
end

def naf_migrations_folder
  "#{naf_folder}migrate/"
end

def naf_migrations
  if Dir.exists?(naf_migrations_folder)
    Dir.entries(naf_migrations_folder).grep(/\.rb$/)
  else
    ['blah']
  end
end
