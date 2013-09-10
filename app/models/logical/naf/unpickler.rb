module ::Logical::Naf
  class Unpickler
    include ::Af::Application::Component

    create_proxy_logger
    attr_reader :preserves,
                :preservables,
                :input_version,
                :references,
                :context

    def initialize(preserves, preservables, input_version)
      @preserves = preserves
      @preservables = preservables
      @input_version = input_version
      @references = {}
      @context = {}
    end

    def cache_all_models(model)
      references.merge!(Hash[model.all.map do |m|
                               logger.detail "caching: #{m.inspect}"
                               [{ association_model_name: model.name, association_value: m.id }, m]
                             end
                            ])
    end

    def retrieve_reference(reference)
      references[reference.symbolize_keys]
    end

    def generic_unpickle(model, preserve, id_method_name = :id)
      if references[{ association_model_name: model.name, association_value: preserve[id_method_name.to_s] }]
        return {}
      end

      attributes = {}

      reference_methods = []
      preserve.each do |method_name, value|
        id_method = method_name.to_sym
        unless id_method_name == id_method
          if value.is_a?(Hash)
            # this is a reference
            reference_instance = retrieve_reference(value)
            if reference_instance.nil?
              logger.error value.inspect
              logger.error { references.map{ |r| r.inspect }.join("\n") }
              raise "couldn't find reference for #{value.inspect} in #{preserve.inspect}"
            end
            attributes[method_name.to_sym] = reference_instance.id
          else
            attributes[method_name.to_sym] = value
          end
        end
      end

      instance = model.new
      attributes.each do |method, value|
        instance.send("#{method}=".to_sym, value)
      end
      instance.save!
      logger.info "created #{instance.inspect}"

      return { { association_model_name: model.name,
                 association_value: preserve[id_method_name.to_s] } => instance }
    end

    def reconstitute
      preservables.each do |model|
        if model.respond_to?(:pre_unpickle)
          model.pre_unpickle(self)
        else
          cache_all_models(model)
        end
      end

      preservables.each do |model|
        model_preserves = preserves[model.name]
        if model_preserves
          model_preserves.each do |model_preserve|
            if model.respond_to?(:unpickle)
              additional_references = model.unpickle(model_preserve, self)
            else
              additional_references = generic_unpickle(model, model_preserve)
            end
            references.merge!(additional_references)
          end
        end
      end

      preservables.each do |model|
        model.post_unpickle(self) if model.respond_to?(:post_unpickle)
      end
    end
  end
end
