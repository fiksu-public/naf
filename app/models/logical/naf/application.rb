module Logical
  module Naf
    class Application

      attr_reader :app

      include ActionView::Helpers::TextHelper

      COLUMNS = [:id,
                 :title,
                 :short_name,
                 :script_type_name,
                 :application_schedules,
                 :deleted]

      FILTER_FIELDS = [:deleted]

      SEARCH_FIELDS = [:title,
                       :command,
                       :short_name]

      def initialize(naf_app)
        @app = naf_app
      end

      def self.search(search)
        application_scope = ::Naf::Application.order("id desc")

        FILTER_FIELDS.each do |field|
          if search.present? and search[field].present?
            application_scope = application_scope.where(field => search[field])
          end
        end

        SEARCH_FIELDS.each do |field|
          if search.present? and search[field].present?
            application_scope = application_scope.where(["lower(#{field}) ~ ?", Regexp.escape(search[field].downcase)])
          end
        end

        application_scope.map{ |physical_app| new(physical_app) }
      end

      def to_hash
        Hash[ COLUMNS.map{ |m| [m, send(m)] } ]
      end

      def command
        @app.command
      end

      def method_missing(method_name, *arguments, &block)
        if @app.respond_to?(method_name)
          @app.send(method_name, *arguments, &block)
        else
          super
        end
      end

    end
  end
end
