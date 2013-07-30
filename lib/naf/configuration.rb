module Naf
  class Configuration
    attr_accessor :schema_name,
                  :model_class,
                  :controller_class,
                  :title,
                  :papertrail_group_id,
                  :layout,
                  :default_page_options

    def initialize
      @model_class = "::ActiveRecord::Base"
      @controller_class = "::ApplicationController"
      @title = "Naf - a Rails Job Scheduling Engine"
      @papertrail_group_id = nil
      @layout = "naf_layout"
      @default_page_options = [10, 20, 50, 100, 250, 500, 750, 1000, 1500, 2000]
    end

  end
end
