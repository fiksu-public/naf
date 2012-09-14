module Naf

  class Configuration
    attr_accessor :schema_name, :model_class, :controller_class, :title, :papertrail_group_id
    
    def initialize
      @model_class = ::ActiveRecord::Base
      @controller_class = ::ApplicationController
      @title = "Naf - a Rails Job Scheduling Engine"
      @papertrail_group_id = nil
    end

    def papertrail_port=(port)
      ENV["PAPERTRAIL_PORT"] = port.to_s
    end

  end

end
