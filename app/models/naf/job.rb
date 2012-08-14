module Naf
  class Job < NafBase

    validates  :application_type_id, :application_run_group_restriction_id, :presence => true
    validates :application_run_group_name, :command, {:presence => true, :length => {:minimum => 3}}
    
    
    belongs_to :application, :class_name => "::Naf::Application"
    belongs_to :application_type, :class_name => "::Naf::ApplicationType"
    belongs_to :application_run_group_restriction, :class_name => "::Naf::ApplicationRunGroupRestriction"

    belongs_to :machine_started_on, :class_name => "::Naf::Machine", :foreign_key => "started_on_machine_id"

    has_many :job_affinity_tabs, :class_name => "::Naf::JobAffinityTab", :dependent => :destroy

    delegate :application_run_group_restriction_name, :to => :application_run_group_restriction

    delegate :script_type_name, :to => :application_type

    attr_accessible :application_type_id, :application_id, :application_run_group_restriction_id, :application_run_group_name, :command


    def application_name     
      application ? application.title : nil
    end

    def machine_started_on_server_name
      machine_started_on ? machine_started_on.server_name : nil
    end

    def machine_started_on_server_address
      machine_started_on ? machine_started_on.server_address : nil
    end
      

  end
end
