module Naf

  class Configuration
    attr_accessor :schema_name, :model_class, :controller_class, :title, :papertrail_group_id, :job_refreshing, :jobs_per_page
    
    def initialize
      @model_class = "::ActiveRecord::Base"
      @controller_class = "::ApplicationController"
      @title = "Naf - a Rails Job Scheduling Engine"
      @papertrail_group_id = nil
      @job_refreshing = false
      @jobs_per_page = 10
    end

  end

end
