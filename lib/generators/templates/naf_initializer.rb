module Naf
  # Please change the Naf.base_class to the controller your app uses for authentication
  # You will need to use the scope resolution operator. Example:  "::AuthenticationController"

  Naf.controller_class = "::ApplicationController"
  Naf.model_class = "ActiveRecord::Base"

  begin
    data = YAML::load(File.open("#{Rails.root}/config/naf_config.yml"))
    Naf.schema_name = data["schema_name"]
    JOB_SYSTEM_SCHEMA_NAME = data["schema_name"]
    MAIN_APP_TITLE = data["main_app_title"]
    
  rescue => e
    puts "Your 'config/job_naf_config.yml' file is formatted incorrectly, or doesn't exist."
    puts e
  end
end
