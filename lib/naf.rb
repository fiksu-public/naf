require "naf/engine"
require 'naf/configuration'

module Naf
  class << self
    attr_writer :configuration

    def configure
      yield(configuration)
    end

    def configuration
      @configuration ||= Configuration.new
    end

    def schema_name
      configuration.schema_name
    end

    def model_class
      configuration.model_class.constantize
    end

    def title
      configuration.title
    end

    def layout
      configuration.layout
    end

    def ui_controller_class
      configuration.ui_controller_class.constantize
    end

    def api_controller_class
      configuration.api_controller_class.constantize
    end

    def api_domain_cookie_name
      configuration.api_domain_cookie_name
    end

    def simple_cluster_authenticator_cookie_expiration_time
      configuration.simple_cluster_authenticator_cookie_expiration_time
    end

    def using_another_database?
      model_class != ActiveRecord::Base
    end
  end
end
