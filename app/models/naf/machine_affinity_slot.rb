module Naf
  class MachineAffinitySlot < NafBase
    validates :machine_id, :affinity_id, :presence => true

    validates_uniqueness_of :affinity_id, :scope => :machine_id, :message => "has been taken for this machine"

    belongs_to :machine, :class_name => '::Naf::Machine'
    belongs_to :affinity, :class_name => '::Naf::Affinity'

    delegate :affinity_name, :affinity_classification_name, :affinity_short_name, :to => :affinity

    attr_accessible :machine_id, :affinity_id, :required

    def machine_server_address
      machine.server_address
    end

    def machine_server_name
      machine.server_name
    end

    def pickle(pickler, associations = nil, ignored_attributes = [:created_at, :updated_at])
      instance_attributes = attributes.symbolize_keys
      ignored_attributes.each do |ignored_attribute|
        instance_attributes.delete(ignored_attribute.to_sym)
      end

      unless associations
        associations = {}
        instance_attributes.keys.select{|key| key.to_s =~ /_id$/}.each do |key|
          association_name = key.to_s[0..-4].to_sym
          association = association(association_name) rescue nil
          if association
            associations[key] = association.options[:class_name].constantize.name
          end
        end
      end

      return Hash[instance_attributes.map { |key, value|
                    if associations[key] == 'Naf::Affinity'
                      [key, { association_model_name: associations[key],
                              association_classification_value: affinity.affinity_classification_id,
                              association_affinity_value: affinity.affinity_name }]
                    elsif associations[key] == 'Naf::Machine'
                      [key, { association_model_name: associations[key], association_value: value }]
                    else
                      [key,value]
                    end
                  } ]
    end

  end
end
