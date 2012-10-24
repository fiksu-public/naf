require 'rails/generators'

class NafGenerator < Rails::Generators::Base

  source_root File.expand_path("../templates", __FILE__)

  argument :schema_name, :type => :string, :default => "naf"

  def add_configuration_files
    filename = "naf.rb"
    filepath = "config/initializers/#{filename}"
    path = "#{Rails.root}/#{filepath}"
    if File.exists?(path)
      puts "Skipping #{filepath} creation, as file already exists!"
    else
      puts "Adding Naf initializer (#{filepath})..."
      template filename, path
    end
  end

  def add_log4r_configuration_files
    directory "config"
  end

  def add_layouts_file
    filename = "naf_layout.html.erb"
    filepath = "app/views/layouts/#{filename}"
    path = "#{Rails.root}/#{filepath}"
    if File.exists?(path)
      puts "Skipping #{filepath} creation, as file already exists!"
    else
      puts "Adding naf_layout (#{filepath})..."
      template filename, path
    end
  end

  def mount_engine
    puts "Mounting Naf::Engine at \"/job_system\" in config/routes.rb..."
    insert_into_file("#{Rails.root}/config/routes.rb", :after => /routes.draw.do\n/) do
      %Q{\n  mount Naf::Engine, :at => "/job_system"\n}
    end
  end


end
