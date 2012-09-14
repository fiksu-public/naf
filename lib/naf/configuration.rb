module Naf

  class Configuration
    attr_accessor :schema_name, :model_class, :controller_class, :title, :papertrail_group_id
    attr_reader :papertrail_port
    
    def initialize
      @model_class = ::ActiveRecord::Base
      @controller_class = ::ApplicationController
      @title = "Naf - a Rails Job Scheduling Engine"
      @papertrail_group_id = nil
    end

    def papertrail_port=(port)
      ENV["PAPERTRAIL_PORT"] = port.to_s
      @papertrail_port = port
    end

  end

end
