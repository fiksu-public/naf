module ::Logical::Naf
  class Pickler
    include ::Af::Application::Component

    create_proxy_logger

    def initialize(naf_version, preservables)
      @preservables = preservables
      @naf_version = naf_version
      @preserves = {}
    end

    def generic_pickle(instance, associations = nil, ignored_attributes = [:created_at, :updated_at])
      instance_attributes = instance.attributes.symbolize_keys
      ignored_attributes.each do |ignored_attribute|
        instance_attributes.delete(ignored_attribute.to_sym)
      end

      unless associations
        associations = {}
        instance_attributes.keys.select{|key| key.to_s =~ /_id$/}.each do |key|
          association_name = key.to_s[0..-4].to_sym
          association = instance.association(association_name) rescue nil
          if association
            associations[key] = association.options[:class_name].constantize.name
          end
        end
      end

      return Hash[instance_attributes.map {|key,value|
                    if associations[key]
                      [key,{:association_model_name => associations[key], :association_value => value}]
                    else
                      [key,value]
                    end
                  }]
    end

    def preserve
      @preservables.each do |model|
        preserve_model(model)
      end
    end

    def preserve_model(model)
      if model.respond_to?(:pickleables)
        pickables = model.pickleables(self)
      else
        pickables = model.all
      end

      @preserves[model.name] = pickables.map do |instance|
        if instance.respond_to?(:pickle)
          instance.pickle(pickler)
        else
          generic_pickle(instance)
        end
      end
    end

    def pickle_jar
      return {
        :version => @naf_version,
        :preserved_at => Time.now,
        :preserves => @preserves
      }
    end
  end
end
