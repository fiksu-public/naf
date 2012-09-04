module Naf
  class Application < NafBase
    
    validates :application_type_id, :command, :title, :presence => true

    validates :title, :uniqueness => true
   
    attr_accessible :title, :command, :application_type_id, :log_level, :application_schedule_attributes

    has_one :application_schedule, :class_name => '::Naf::ApplicationSchedule', :dependent => :destroy
    belongs_to :application_type, :class_name => '::Naf::ApplicationType'
    delegate :script_type_name, :to => :application_type

    accepts_nested_attributes_for :application_schedule, :allow_destroy => true


    def last_finished_job
      return Naf::Job.recently_queued
                     .where(:finished_at => Naf::Job.recently_queued.where(:application_id => id).select("max(finished_at)"))
                     .first
    end

  end
end
