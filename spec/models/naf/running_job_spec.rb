require 'spec_helper'

module Naf
  describe RunningJob do

    # Mass-assignment
    [:application_id,
     :application_type_id,
     :command,
     :application_run_group_restriction_id,
     :application_run_group_name,
     :application_run_group_limit,
     :started_on_machine_id,
     :pid,
     :request_to_terminate,
     :marked_dead_by_machine_id,
     :log_level,
     :started_at].each do |a|
      it { should allow_mass_assignment_of(a) }
    end

    [:id,
     :created_at,
     :updated_at].each do |a|
      it { should_not allow_mass_assignment_of(a) }
    end

    #---------------------
    # *** Associations ***
    #+++++++++++++++++++++

    it { should belong_to(:historical_job) }
    it { should belong_to(:application) }
    it { should belong_to(:application_type) }
    it { should belong_to(:application_run_group_restriction) }
    it { should belong_to(:started_on_machine) }
    it { should belong_to(:marked_dead_by_machine) }

    #--------------------
    # *** Validations ***
    #++++++++++++++++++++

    it { should validate_presence_of(:application_type_id) }
    it { should validate_presence_of(:command) }
    it { should validate_presence_of(:application_run_group_restriction_id) }

    #----------------------
    # *** Class Methods ***
    #++++++++++++++++++++++

  end
end
