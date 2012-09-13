module Naf

  class Configurator
    
    def self.configure(file = 'config/naf_config.yml')
      begin
        data = YAML::load(File.open("#{Rails.root}/#{file}"))
        schema_name = data["schema_name"] || "naf"
        controller_class = data["controller_class"] || "::ApplicationController"
        model_class = data["model_class"] || "ActiveRecord::Base"
        main_app_title = data["main_app_title"] || "Naf - a Rails Job Scheduling Engine"
        # Module Attributes
        Naf.schema_name = schema_name
        Naf.controller_class = controller_class
        Naf.model_class = model_class
  
        # Constants
        Naf.const_set(:JOB_SYSTEM_SCHEMA_NAME, schema_name)
        Naf.const_set(:MAIN_APP_TITLE,  main_app_title)
        if group_id = data["papertrail_group_id"]
          Naf.const_set(:PAPERTRAIL_GROUP_ID, group_id)
        end

        # Setting the environment variable so all child processes of 
        # Process::Naf::Runner.run will get the same logger configuration
        if data["loggers"].present? and data["outputters"].present?
          ENV["LOG_CONFIGURATION_FILE"] = file
        end
      rescue => e
        puts "Please fix your config file: #{file}"
        raise e
      end



    end

  end

end
