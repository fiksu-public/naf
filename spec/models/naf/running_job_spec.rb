require 'spec_helper'

module Naf
  describe RunningJob do
    let!(:running_job) { FactoryGirl.create(:running_job_base) }

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
     :started_at,
     :tags].each do |a|
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

    describe "#started_on" do
      let(:machine) { mock_model(Machine) }
      before do
        running_job.started_on_machine = machine
      end

      it "return the correct job record" do
        ::Naf::RunningJob.should_receive(:where).and_return([running_job])
        ::Naf::RunningJob.started_on(machine).should == [running_job]
      end
    end

    describe "#started_on_invocation" do
      let!(:invocation) { FactoryGirl.create(:machine_runner_invocation) }
      before do
        running_job.historical_job.machine_runner_invocation = invocation
        running_job.historical_job.save!
      end

      it "return the correct job record" do
        ::Naf::RunningJob.started_on_invocation(invocation.id).should == [running_job]
      end

      it "return nothing when no running jobs are associated invocation" do
        ::Naf::RunningJob.started_on_invocation(invocation.id + 1).should == []
      end
    end

    describe "#in_run_group" do
      it "return the correct job record" do
        ::Naf::RunningJob.should_receive(:where).and_return([running_job])
        ::Naf::RunningJob.in_run_group('test').should == [running_job]
      end
    end

    describe "#assigned_jobs" do
      let(:machine) { mock_model(Machine) }

      it "return the correct job record" do
        ::Naf::RunningJob.stub(:started_on).and_return([running_job])
        ::Naf::RunningJob.assigned_jobs(machine).should == [running_job]
      end
    end

    describe "#affinity_weights" do
      let(:machine) { FactoryGirl.create(:machine) }
      before do
        cpu_affinity = FactoryGirl.create(:affinity, id: 4, affinity_name: 'cpus')
        memory_affinity = FactoryGirl.create(:affinity, id: 5, affinity_name: 'memory')
        FactoryGirl.create(:job_affinity_tab_base, historical_job: running_job.historical_job,
                                                   affinity: cpu_affinity,
                                                   affinity_parameter: 1.0)
        FactoryGirl.create(:job_affinity_tab_base, historical_job: running_job.historical_job,
                                                   affinity: memory_affinity,
                                                   affinity_parameter: 1.0)

        running_job.started_on_machine = machine
        running_job.save!
      end

      it "return the correct sum of affinity parameters for each affinity" do
        ::Naf::RunningJob.affinity_weights(machine).should == { 1 => 0.0,
                                                                2 => 0.0,
                                                                3 => 0.0,
                                                                4 => 1.0,
                                                                5 => 1.0 }
      end
    end

    #-------------------------
    # *** Instance Methods ***
    #+++++++++++++++++++++++++

    describe "#add_tags" do
      before do
        running_job.tags = "{$pre-work}"
      end

      it "insert unique tag" do
        running_job.add_tags([::Naf::HistoricalJob::SYSTEM_TAGS[:work]])
        running_job.tags.should == "{$pre-work,$work}"
      end

      it "not insert non-unique tag" do
        running_job.add_tags([::Naf::HistoricalJob::SYSTEM_TAGS[:pre_work]])
        running_job.tags.should == "{$pre-work}"
      end
    end

    describe "#remove_tags" do
      before do
        running_job.tags = "{$pre-work}"
      end

      it "remove existing tag" do
        running_job.remove_tags([::Naf::HistoricalJob::SYSTEM_TAGS[:pre_work]])
        running_job.tags.should == "{}"
      end

      it "not update tags when removing non-existing tag" do
        running_job.remove_tags([::Naf::HistoricalJob::SYSTEM_TAGS[:work]])
        running_job.tags.should == "{$pre-work}"
      end
    end

    describe "#remove_all_tags" do
      before do
        running_job.tags = "{$pre-work}"
      end

      it "remove any existing tags" do
        running_job.remove_all_tags
        running_job.tags.should == "{}"
      end
    end

  end
end
