module Naf
  class ApplicationScheduleAffinityTab < NafBase
    # Protect from mass-assignment issue
    attr_accessible :application_schedule_id,
                    :affinity_id,
                    :affinity_parameter

    #---------------------
    # *** Associations ***
    #+++++++++++++++++++++

    belongs_to :application_schedule,
      class_name: '::Naf::ApplicationSchedule'
    belongs_to :affinity,
      class_name: '::Naf::Affinity'

    #--------------------
    # *** Validations ***
    #++++++++++++++++++++

    validates :application_schedule_id,
              :affinity_id, presence: true
    validates_uniqueness_of :affinity_id, scope: :application_schedule_id,
                                          message: 'has already been taken for this script'

    #--------------------
    # *** Delegations ***
    #++++++++++++++++++++

    delegate :affinity_name,
             :affinity_classification_name, to: :affinity


    #-------------------------
    # *** Instance Methods ***
    #+++++++++++++++++++++++++

    def script_title
      application_schedule.title
    end

    def application
      if schedule = application_schedule
        application_schedule.application
      else
        nil
      end
    end

    def self.pickleables(pickler)
      self.joins([application_schedule: :application]).
        where('applications.deleted = false')
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
                    elsif associations[key] == 'Naf::ApplicationSchedule'
                      [key, { association_model_name: associations[key], association_value: value }]
                    else
                      [key,value]
                    end
                  } ]
    end

  end
end
