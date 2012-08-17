# desc "Explaining what the task does"
# task :naf do
#   # Task goes here
# end

namespace :naf do
  task :schema_rollback => :environment do
    matching_migrations = Dir.entries("#{Rails.root}/db/migrate").grep(/create_job_system/)
    if naf_migration = matching_migrations.first
      naf_migration_version = naf_migration.scan(/[0-9]+/).first
      ENV['VERSION'] = naf_migration_version
      puts "Rolling back the Naf Schema Migration"
      Rake::Task['db:migrate:down'].invoke
    end
  end

  task :remove_migration_file => [:environment, :schema_rollback] do
    file = Dir.entries("#{Rails.root}/db/migrate").grep(/create_job_system/).first
    file_path = "#{Rails.root}/db/migrate/#{file}"
    if File.exists?(file_path)
      puts "Removing file: #{file}"
      File.delete(file_path)
    end
  end

  task :system_teardown => :environment do
    files_to_remove = [
      "config/initializers/job_system_initializer.rb", 
      "config/job_system_schema_config.yml"
    ]
    edit_file_line_regex_hash = { 
      "app/assets/javascripts/application.js"  => %r{\/\/= require naf\s*\n},
      "app/assets/stylesheets/application.css" => %r{\*= require naf\s*\n}, 
      "config/routes.rb" => %r{mount Naf::Engine, :at => "/job_system"\s*\n}
    } 

    files_to_remove.each do |file|
      file_path = "#{Rails.root}/#{file}"
      if File.exists?(file_path)
        puts "Removing file: #{file}"
        File.delete(file_path)
      end
    end
    edit_file_line_regex_hash.each do |file, regex|
      puts "Undoing Naf's changes to #{file}"
      file_path = "#{Rails.root}/#{file}"
      gsub_file(file_path, regex, '')
    end
  end

  task :teardown => [:system_teardown, :remove_migration_file] do
  end

end


def gsub_file(path, regexp, *args, &block)
  content = File.read(path).gsub(regexp, *args, &block)
  File.open(path, 'wb') { |file| file.write(content) }
end
