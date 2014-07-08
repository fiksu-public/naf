module Naf
  class Configuration
    attr_accessor :schema_name,
                  :model_class,
                  :ui_controller_class,
                  :api_controller_class,
                  :title,
                  :layout,
                  :default_page_options,
                  :api_domain_cookie_name,
                  :simple_cluster_authenticator_cookie_expiration_time,
                  :metric_tags,
                  :metric_send_delay

    def initialize
      @model_class = "::ActiveRecord::Base"
      @ui_controller_class = "::ApplicationController"
      @title = "Naf - a Rails Job Scheduling Engine"
      @layout = "naf_layout"
      @default_page_options = [10, 20, 50, 100, 250, 500, 750, 1000, 1500, 2000]
      @api_controller_class = "Naf::ApiSimpleClusterAuthenticatorApplicationController"
      @simple_cluster_authenticator_cookie_expiration_time = 1.week
      @api_domain_cookie_name = "naf_#{Rails.application.class.parent.name.underscore}"
      @metric_tags = ["#{Rails.env}"]
      @metric_send_delay = 120
    end

  end
end
