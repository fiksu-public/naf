require 'spec_helper'

module Naf
  describe QueuedJob do

    # Mass-assignment
    [:application_id,
     :application_type_id,
     :command,
     :application_run_group_restriction_id,
     :application_run_group_name,
     :application_run_group_limit,
     :priority].each do |a|
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

    #--------------------
    # *** Validations ***
    #++++++++++++++++++++

    it { should validate_presence_of(:application_type_id) }
    it { should validate_presence_of(:command) }
    it { should validate_presence_of(:application_run_group_restriction_id) }
    it { should validate_presence_of(:priority) }

    #----------------------
    # *** Class Methods ***
    #++++++++++++++++++++++

    describe "#order_by_priority" do
      let!(:high_priority_job) { FactoryGirl.create(:queued_job, priority: 1) }
      let!(:low_priority_job) { FactoryGirl.create(:queued_job, priority: 2) }
      let!(:low_priority_job2) { FactoryGirl.create(:queued_job, priority: 2) }

      it "return records in correct order" do
        Naf::QueuedJob.order_by_priority.
          should == [high_priority_job, low_priority_job, low_priority_job2]
      end
    end

  end
end