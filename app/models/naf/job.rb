module Naf
  class Job < NafBase

    validates  :application_id, :application_run_group_restriction_id, :presence => true
    validates :application_run_group_name, {:presence => true, :length => {:minimum => 3}}
    
    
    belongs_to :application, :class_name => "::Naf::Application"

    belongs_to :application_run_group_restriction, :class_name => "::Naf::ApplicationRunGroupRestriction"

    belongs_to :machine_started_on, :class_name => "::Naf::Machine", :foreign_key => "started_on_machine_id"

    has_many :job_affinity_tabs, :class_name => "::Naf::JobAffinityTab", :dependent => :destroy

    delegate :application_run_group_restriction_name, :to => :application_run_group_restriction

    delegate :command, :script_type_name, :title, :to => :application

    attr_accessible :application_id, :application_run_group_restriction_id, :application_run_group_name


    def machine_started_on_server_name
      machine_started_on ? machine_started_on.server_name : nil
    end

    def machine_started_on_server_address
      machine_started_on ? machine_started_on.server_address : nil
    end
      

  end
end
