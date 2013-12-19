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

    def controller_class
      configuration.controller_class.constantize
    end

    def title
      configuration.title
    end

    def layout
      configuration.layout
    end

    def using_another_database?
      model_class != ActiveRecord::Base
    end
  end
end
