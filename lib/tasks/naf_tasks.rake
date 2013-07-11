require 'fileutils'

# Add methods for aliasing and overriding rake tasks                                                                                                                         
# From: http://metaskills.net/2010/5/26/the-alias_method_chain-of-rake-override-rake-task 

Rake::TaskManager.class_eval do
  def alias_task(fq_name)
    raise "Task '#{fq_name}' not found" unless @tasks.has_key?(fq_name)

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
  namespace :isolate do
    desc "Custom isolation Engine migrations to db/naf/migrate folder, for use on non-primary database"
    task :migrations do

      puts "Moving naf migration files to folder: #{isolated_naf_migrations_folder}"

      FileUtils.mkdir(isolated_naf_folder) unless Dir.exists?(isolated_naf_folder)
      FileUtils.mkdir(isolated_naf_migrations_folder) unless Dir.exists?(isolated_naf_migrations_folder)

      source_folder = "#{Rails.root}/db/migrate"

      Dir.entries(source_folder).grep(/\.naf\.rb/).each do |migration_file|
        file_path = "#{source_folder}/#{migration_file}"
        puts "#{isolated_naf_migrations_folder}/#{migration_file}"
        if File.exists?("#{isolated_naf_migrations_folder}#{migration_file}")
          puts "\t#{migration_file} already exists, skipping"
        else
          puts "\t #{file_path} => #{isolated_naf_migrations_folder}#{migration_file}"
          FileUtils.mv(file_path, isolated_naf_migrations_folder)
        end
      end

    end
  end

  namespace :janitor do
    desc "create partitioning infrastructure for naf tables"
    task :infrastructure => :environment do
      model_names = [::Naf::HistoricalJob.name,
                     ::Naf::HistoricalJobPrerequisite.name,
                     ::Naf::HistoricalJobAffinityTab.name,
                     ::Naf::ApplicationSchedulePrerequisite.name]
      ::Logical::Naf::CreateInfrastructure.new(model_names).work
    end
  end

  namespace :db do
    desc "Custom migrate task, connects to correct database, migrations found in db/naf/migrate"
    task :migrate => :environment do
      if using_another_database? and naf_migrations.size > 0
        puts "Running naf migrations with database configuration: #{naf_environment}"
        puts naf_migrations
        connect_to_naf_database do
          version = ENV['VERSION'] ?  ENV['VERSION'].to_i : nil
          ActiveRecord::Migrator.migrate(isolated_naf_migrations_folder, version )
        end
      else
        #Invoke the standard migration task, within the Naf Engine scope
        ENV['SCOPE'] = 'naf'
        Rake::Task['db:migrate'].invoke
      end
    end

    desc "Perform a rollback on the on the naf migrations"
    task :rollback => :environment do
      if using_another_database? and naf_migrations.size > 0
        connect_to_naf_database do
          step = ENV['STEP'] ? ENV['STEP'].to_i : 1
          ActiveRecord::Migrator.rollback(isolated_naf_migrations_folder, step)
        end
      else
        ENV['SCOPE'] = 'naf'
        Rake::Task['db:rollback'].invoke
      end
    end

    namespace :migrate do

      desc 'Runs the "up" for a given migration VERSION.'
      task :up => [:environment] do
        if using_another_database? and naf_migrations.size > 0
          connect_to_naf_database do
            version = ENV['VERSION'] ? ENV['VERSION'].to_i : nil
            raise 'VERSION is required' unless version
            ActiveRecord::Migrator.run(:up, [isolated_naf_migrations_folder], version)
          end
        else
          puts "You are using the primary database for Naf, please run:  rake db:migrate:up VERSION=x"
        end
      end

      desc 'Runs the "down" for a given migration VERSION.'
      task :down => [:environment] do
        if using_another_database? and naf_migrations.size > 0
          connect_to_naf_database do
            version = ENV['VERSION'] ? ENV['VERSION'].to_i : nil
            raise 'VERSION is required' unless version
            ActiveRecord::Migrator.run(:down, [isolated_naf_migrations_folder], version)
          end
        else
          puts "You are using the primary database for Naf, please run:  rake db:migrate:down VERSION=x"
        end
      end

      desc "Show the status of migrations"
      task :status => :environment do
        if using_another_database? and naf_migrations.size > 0
          connect_to_naf_database do
            config = ActiveRecord::Base.configurations[naf_environment]
            unless ActiveRecord::Base.connection.table_exists?(ActiveRecord::Migrator.schema_migrations_table_name)
              puts 'Schema migrations table does not exist yet.'
              next  # means "return" for rake task
            end
            db_list = ActiveRecord::Base.connection.select_values("SELECT version FROM #{ActiveRecord::Migrator.schema_migrations_table_name}")
            file_list = []
            Dir.foreach(isolated_naf_migrations_folder) do |file|
              # only files matching "20091231235959_some_name.rb" pattern
              if match_data = /^(\d{14})_(.+)\.rb$/.match(file)
                status = db_list.delete(match_data[1]) ? 'up' : 'down'
                file_list << [status, match_data[1], match_data[2].humanize]
              end
            end
            db_list.map! do |version|
              ['up', version, '********** NO FILE **********']
            end
            # output
            puts "\ndatabase: #{config['database']}\n\n"
            puts "#{'Status'.center(8)}  #{'Migration ID'.ljust(14)}  Migration Name"
            puts "-" * 50
            (db_list + file_list).sort_by {|migration| migration[1]}.each do |migration|
              puts "#{migration[0].center(8)}  #{migration[1].ljust(14)}  #{migration[2]}"
            end
          end
        else
          puts "You are using the primary database for Naf, please run: rake db:migrate:status"
        end
      end
    end

  namespace :structure do
    desc "Dump the naf_development schema"
    task :dump => :environment do
      env = "naf_#{::Rails.env}"
      config = ActiveRecord::Base.configurations[env]
      ENV['PGHOST'] = config["host"] if config["host"]
      ENV['PGPORT'] = config["port"].to_s if config["port"]
      ENV['PGPASSWORD'] = config["password"].to_s if config["password"]
      search_path = "naf*"
      command = "pg_dump -i -U \"#{config["username"]}\" -s -x -O"
      ( config["exclude"] || [] ).each {|e| command << " -T \"#{e}\""}
      command << " -f db/#{env}_structure.sql --schema=#{search_path} #{config["database"]} > /dev/null 2>&1"
      `#{command}`
      raise "Error dumping database structure for #{env}" if $?.exitstatus == 1
    end
  end

  namespace :test do
     desc "Drop the Naf Test database"
      task :purge => :environment do
        abcs = ActiveRecord::Base.configurations
        config = abcs['naf_test']
        ActiveRecord::Base.clear_active_connections! 
        ActiveRecord::Base.establish_connection(config.merge('database' => 'postgres', 'schema_search_path' => 'public')) 
        ActiveRecord::Base.connection.drop_database config['database']
        @encoding = config['encoding'] || ENV['CHARSET'] || 'utf8'
        begin
          ActiveRecord::Base.establish_connection(config.merge('database' => 'postgres', 'schema_search_path' => 'public'))
          ActiveRecord::Base.connection.create_database(config['database'], config.merge('encoding' => @encoding))
          ActiveRecord::Base.establish_connection(config)
        rescue Exception => e
          $stderr.puts e, *(e.backtrace)
          $stderr.puts "Couldn't create database for #{config.inspect}"
        end
      end
      desc "Clone naf_development to naf_test"
      task :clone_structure => [ "naf:db:structure:dump", "naf:db:test:purge" ] do
        abcs = ActiveRecord::Base.configurations
        config = abcs['naf_test']
        ENV['PGHOST'] = config["host"] if config["host"]
        ENV['PGPORT'] = config["port"].to_s if config["port"]
        ENV['PGPASSWORD'] = config["password"].to_s if config["password"]
        `psql -U "#{config["username"]}" -f db/naf_#{::Rails.env}_structure.sql #{config["database"]}`
        raise "Error loading database structure for #{env}" if $?.exitstatus == 1
      end
    end
  end

  desc "Undo all of the naf schema migrations"
  task :schema_rollback => :environment do
    puts "Rolling back all of Naf migrations"
    if using_another_database? and naf_migrations.size > 0
      connect_to_naf_database do
        ActiveRecord::Migrator.migrate(isolated_naf_migrations_folder, 0)
      end
    else
      ENV['SCOPE'] = 'naf'
      ENV['VERSION'] = '0'
      Rake::Task['db:migrate'].invoke
    end
  end

  desc "Delete all of the naf schema migrations files that were installed"
  task :remove_migration_files => [:environment, :schema_rollback] do
    naf_migrations.each do |migration| 
      if using_another_database? and naf_migrations.size > 0
        file_path = "#{isolated_naf_migrations_folder}#{migration}"
      else
        file_path = "#{standard_migrations_folder}#{migration}"
      end
      if File.exists?(file_path)
        puts "Removing migration file: #{migration}"
        File.delete(file_path)
      end
    end
    if Dir.exists?(isolated_naf_migrations_folder)
      puts "Removing folder #{isolated_naf_migrations_folder}"
      FileUtils.rmdir(isolated_naf_migrations_folder)
    end
    if Dir.exists?(isolated_naf_folder)
      puts "Removing folder #{isolated_naf_folder}"
      FileUtils.rmdir(isolated_naf_folder)
    end
  end

  desc "Deletes initalizers, configs that were installed, revert edit to config/routes"
  task :system_teardown => :environment do
    # The first two files configured to be removed, if someone is using an older versions of naf
    files_to_remove = [
      "config/initializers/job_system_initializer.rb",
      "config/job_system_config.yml",
      "config/initializers/naf_initializer.rb", 
      "config/initializers/naf.rb", 
      "config/naf_log4r.yml",
      "config/naf_config.yml"
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

  desc "remove partitioning infrastructure for naf tables"
  task :remove_partitions => :environment do
    klasses = [::Naf::HistoricalJob, ::Naf::HistoricalJobPrerequisite, ::Naf::HistoricalJobAffinityTab]
    existing_schemas = database_schemas
    schemas = klasses.map{ |klass| klass.configurator.schema_name }
    if using_another_database?
      connect_to_naf_database do
        schemas.each do |schema|
          ActiveRecord::Base.connection.execute("DROP SCHEMA #{schema} CASCADE") if existing_schemas.include?(schema)
        end
      end
    else
      schemas.each do |schema|
        ActiveRecord::Base.connection.execute("DROP SCHEMA #{schema} CASCADE") if existing_schemas.include?(schema)
      end
    end
  end
  desc "The master task for completely expunging the installation of the naf Engine"
  task :teardown => [:system_teardown, :remove_migration_files, :remove_partitions] do
  end

end

# Helper Methods

def database_schemas
  params = ["SELECT nspname FROM pg_namespace WHERE nspname !~ '^pg_.*' AND nspname NOT IN ('information_schema') ORDER by nspname; ", 'SCHEMA']
  if using_another_database?
    connect_to_naf_database do
      return ActiveRecord::Base.connection.query(*params).flatten
    end
  else
    return ActiveRecord::Base.connection.query(*params).flatten
  end
end

# Transactions method to connect to the specific database
# you want the naf tables to live in
def connect_to_naf_database
  original = ActiveRecord::Base.remove_connection
  ActiveRecord::Base.establish_connection(naf_environment)
  yield
ensure
  ActiveRecord::Base.establish_connection original
end

# Figure out if you are using another database for naf
def using_another_database?
  return naf_environment == "naf_#{Rails.env}"
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
# Used right now just to revert config/routes.rb
def gsub_file(path, regexp, *args, &block)
  content = File.read(path).gsub(regexp, *args, &block)
  File.open(path, 'wb') { |file| file.write(content) }
end

def standard_migrations_folder
  "#{Rails.root}/db/migrate/"
end

def isolated_naf_folder
  "#{Rails.root}/db/naf/"
end

def isolated_naf_migrations_folder
  "#{isolated_naf_folder}migrate/"
end

def naf_migrations
  if using_another_database?
    unless Dir.exists?(isolated_naf_folder) and Dir.exists?(isolated_naf_migrations_folder)
      raise NafConfigurationError
    else
      Dir.entries(isolated_naf_migrations_folder).grep(/\.naf\.rb$/)
    end
  else
    Dir.entries(standard_migrations_folder).grep(/\.naf\.rb$/)
  end
end

class NafUsageError < Exception
end

class NafConfigurationError < Exception
end
