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

# Fix according to this unreleased pull request:
# https://github.com/rails/rails/pull/4132
namespace :db do
  namespace :structure do
    desc 'Dump the database structure to db/structure.sql. Specify another file with DB_STRUCTURE=db/my_structure.sql'
    override_task :dump => :environment do
      abcs = ActiveRecord::Base.configurations
      filename = ENV['DB_STRUCTURE'] || File.join(Rails.root, "db", "structure.sql")
      case abcs[Rails.env]['adapter']
      when /mysql/, 'oci', 'oracle'
        ActiveRecord::Base.establish_connection(abcs[Rails.env])
        File.open(filename, "w:utf-8") { |f| f << ActiveRecord::Base.connection.structure_dump }
      when /postgresql/
        set_psql_env(abcs[Rails.env])
        search_path = abcs[Rails.env]['schema_search_path']
        unless search_path.blank?
          search_path = search_path.split(",").map{|search_path_part| "--schema=#{search_path_part.strip}" }.join(" ")
        end
        `pg_dump -i -s -x -O -f #{filename} #{search_path} #{abcs[Rails.env]['database']}`
        raise 'Error dumping database' if $?.exitstatus == 1
      File.open(filename, "a") { |f| f << "SET search_path TO #{ActiveRecord::Base.connection.schema_search_path};\n\n" }
      when /sqlite/
        dbfile = abcs[Rails.env]['database']
        `sqlite3 #{dbfile} .schema > #{filename}`
      when 'sqlserver'
        `smoscript -s #{abcs[Rails.env]['host']} -d #{abcs[Rails.env]['database']} -u #{abcs[Rails.env]['username']} -p #{abcs[Rails.env]['password']} -f #{filename} -A -U`
      when "firebird"
        set_firebird_env(abcs[Rails.env])
        db_string = firebird_db_string(abcs[Rails.env])
        sh "isql -a #{db_string} > #{filename}"
      else
        raise "Task not supported by '#{abcs[Rails.env]["adapter"]}'"
      end
      if ActiveRecord::Base.connection.supports_migrations?
        File.open(filename, "a") { |f| f << ActiveRecord::Base.connection.dump_schema_information }
      end
    end
  end
end
