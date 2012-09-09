module Logical
  module Naf
    class CreateInfrastructure
      include ::Af::Application::SafeProxy

      def initialize(model_names)
        @model_names = model_names
      end

      def logger
        return af_logger(self.class.name)
      end

      def work
        first_model = nil
        begin
          @model_names.each do |target_model_name|
            logger.info "target model: #{target_model_name}"
            target_model = target_model_name.constantize rescue nil
            if target_model.nil?
              logger.error "couldn't find target_model #{target_model_name}"
            else
              unless first_model
                target_model.connection.begin_db_transaction
                first_model = target_model
              end
              begin
                logger.info "#{target_model_name}: creating infrastructure"
                target_model.create_infrastructure
                logger.info "#{target_model_name}: creating new partitions"
                target_model.create_new_partitions
                logger.info "#{target_model_name}: done"
              rescue StandardError => e
                logger.error "couldn't create infrastructure for: #{target_model_name}, #{e.message}"
                logger.error e.backtrace.join("\n")
              end
            end
          end
        ensure
          if first_model
            first_model.connection.commit_db_transaction
          end
        end
      end
    end
  end
end
