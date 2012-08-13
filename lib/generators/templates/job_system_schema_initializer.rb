module Naf
  # Please change CONTROLLER_NAME_STR to the controller your app uses for authentication
  # You will need to use the scope resolution operator. Example:  "::AuthenticationController"
  CONTROLLER_NAME_STR = "::ApplicationController"
  begin
    data = YAML::load(File.open("#{Rails.root}/config/job_system_schema_config.yml"))
    job_system_config = data["job_system_configuration"]
    JOB_SYSTEM_SCHEMA_NAME = job_system_config["schema_name"]
  rescue => e
    puts "Your 'config/job_system_config.yml' file is formatted incorrectly."
    puts e
  end
end
