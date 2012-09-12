require 'rails/generators'

class NafSystemGenerator < Rails::Generators::Base

  source_root File.expand_path("../templates", __FILE__)

  argument :schema_name, :type => :string, :default => "naf"

  def add_naf_intializer
    filename = "naf_initializer.rb"
    filepath = "config/initializers/#{filename}"
    path = "#{Rails.root}/#{filepath}"
    if File.exists?(path)
      puts "Skipping #{filepath} creation, as file already exists!"
    else
      puts "Adding Naf initializer (#{filepath})..."
      template filename, path
    end
  end

  def add_naf_config
    filename = "naf_config.yml"
    filepath = "config/#{filename}"
    path = "#{Rails.root}/#{filepath}"
    if File.exists?(path)
      puts "Skipping #{filepath} creation, as file already exists!"
    else
      puts "Adding Naf config (#{filepath})..."
      template filename, path
    end
  end

  def add_log4r_config
    filename = "naf_log4r.yml"
    filepath = "config/#{filename}"
    path = "#{Rails.root}/#{filepath}"
    if File.exists?(path)
      puts "Skipping #{filepath} create, as file already exists!"
    else
      puts "Adding Log4r config (#{filepath})..."
      template filename, path
    end
  end

  def mount_engine
    puts "Mounting Naf::Engine at \"/job_system\" in config/routes.rb..."
    insert_into_file("#{Rails.root}/config/routes.rb", :before => /$\s*end\n/) do
      %Q{\n  mount Naf::Engine, :at => "/job_system"\n}
    end
  end


end
