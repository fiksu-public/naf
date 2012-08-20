namespace :naf do

  task :schema_rollback => :environment do
    naf_migrations.each do |migration|
      migration_version = migration.scan(/[0-9]+/).first
      ENV['VERSION'] = migration_version
      puts "Rolling back the Naf migration, file: #{migration}"
      Rake::Task['db:migrate:down'].invoke
    end
  end

  task :remove_migration_files => [:environment, :schema_rollback] do
    naf_migrations.each do |migration| 
      file_path = "#{Rails.root}/db/migrate/#{migration}"
      if File.exists?(file_path)
        puts "Removing migration file: #{migration}"
        File.delete(file_path)
      end
    end
  end

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

  task :teardown => [:system_teardown, :remove_migration_files] do
  end

end


def gsub_file(path, regexp, *args, &block)
  content = File.read(path).gsub(regexp, *args, &block)
  File.open(path, 'wb') { |file| file.write(content) }
end

def naf_migrations
  Dir.entries("#{Rails.root}/db/migrate").grep(/\.naf\.rb$/)
end
