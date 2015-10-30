require 'spec_helper'

module Naf
  describe Machine do
    let!(:machine) { FactoryGirl.create(:machine) }

    # Mass-assignment
    [:server_address,
     :server_name,
     :server_note,
     :enabled,
     :thread_pool_size,
     :log_level,
     :marked_down,
     :short_name,
     :deleted].each do |a|
      it { is_expected.to allow_mass_assignment_of(a) }
    end

    [:id,
     :created_at,
     :updated_at].each do |a|
      it { is_expected.not_to allow_mass_assignment_of(a) }
    end

    #---------------------
    # *** Associations ***
    #+++++++++++++++++++++

    it { is_expected.to have_many(:machine_affinity_slots) }
    it { is_expected.to have_many(:affinities) }
    it { is_expected.to have_many(:machine_runners) }

    #--------------------
    # *** Validations ***
    #++++++++++++++++++++

    it { is_expected.to validate_presence_of(:server_address) }
    it { is_expected.to validate_uniqueness_of(:short_name) }

    ['', 'aa', 'aA', 'Aa', 'AA', '_a', 'a1', 'A1', '_9'].each do |v|
      it { is_expected.to allow_value(v).for(:short_name) }
    end

    ['1_', '3A', '9a'].each do |v|
      it { is_expected.not_to allow_value(v).for(:short_name) }
    end

    [-2147483647, 2147483646, 0, 1].each do |v|
      it { is_expected.to allow_value(v).for(:thread_pool_size) }
    end

    [-2147483648, 2147483647, 1.0].each do |v|
      it { is_expected.not_to allow_value(v).for(:thread_pool_size) }
    end

    context "with regard to checking the schedules" do
      before do
        machine.mark_checked_schedule
      end

      it "should be time to check the schedules if it's been longer than the check period" do
        check_period = Time.now - Machine.last_time_schedules_were_checked
        expect(Machine.is_it_time_to_check_schedules?(check_period)).to be_truthy
      end

      it "should not be time to check the schedules if it's been shorter than the check period" do
        expect(Machine.is_it_time_to_check_schedules?(1.minute)).to be_falsey
      end
    end

    context "when created" do
      it "should not save with a bad address" do
        bad_machine = FactoryGirl.build(:machine, server_address: "21312")
        expect(bad_machine.save).not_to be_truthy
        expect(bad_machine.errors[:server_address].size).to eq 1
      end

      it "should be found by the enabled scope" do
        expect(Machine.enabled).to include(machine)
      end

      it "should be not be stale" do
        expect(machine.is_stale?(1)).to be_falsey
      end
    end

    context "when updating its status" do
      let!(:time_before_update) { Time.zone.now }

      it "should mark schedules as checked" do
        machine.mark_checked_schedule
        expect(machine.last_checked_schedules_at).to be > time_before_update
        expect(machine.last_checked_schedules_at).to be < Time.zone.now
      end

      it "should mark itself as alive" do
        machine.mark_alive
        expect(machine.last_seen_alive_at).to be > time_before_update
        expect(machine.last_seen_alive_at).to be < Time.zone.now
      end

      it "should become stale" do
        machine.mark_alive
        sleep(2.0)
        expect(machine.is_stale?(1)).to be_truthy
      end
    end

    context "when marking itself as dead" do
      it "should un-enable itself, and mark child proceses as dead" do
        mock_machine_logger = double('machine_logger')
        expect(mock_machine_logger).to receive(:alarm).and_return(nil)
        dying_machine = machine
        expect(dying_machine).to receive(:machine_logger).and_return(mock_machine_logger)
        expect(dying_machine).to receive(:mark_processes_as_dead).and_return(nil)
        dying_machine.mark_machine_down(dying_machine)
        expect(dying_machine.marked_down).to be_truthy
      end
    end

    context "when updating the machine" do
      it "should not save when enabled and deleted are true" do
        bad_machine = FactoryGirl.build(:machine, enabled: true, deleted: true)
        expect(bad_machine.save).not_to be_truthy
        expect(bad_machine.errors.messages[:enabled]).not_to be_nil
      end

      it "should save when enabled is true and deleted is false" do
        machine = FactoryGirl.build(:machine, enabled: true, deleted: false)
        expect(machine.save).to be_truthy
      end
    end

    #----------------------
    # *** Class Methods ***
    #++++++++++++++++++++++

    describe "#enabled" do
      before do
        machine.update_attributes!(enabled: true)
        FactoryGirl.create(:machine_two, enabled: false, deleted: true)
      end

      it "return the correct machine" do
        expect(::Naf::Machine.enabled.to_a).to eq([machine])
      end
    end

    describe "#up" do
      it "return the correct status" do
        FactoryGirl.create(:machine, marked_down: true)
        expect(::Naf::Machine.down.to_a).to eq([machine])
      end
    end

    describe "#down" do
      it "return the correct status" do
        machine2 = FactoryGirl.create(:machine, marked_down: true)
        expect(::Naf::Machine.down.to_a).to eq([machine2])
      end
    end

    describe "#machine_ip_address" do
      it "return the correct ip address" do
        allow(::Naf::Machine).to receive(:hostname).and_raise(StandardError)
        expect(::Naf::Machine.machine_ip_address).to eq('127.0.0.1')
      end

      it "return the correct ip address" do
        allow(::Naf::Machine).to receive(:hostname).and_return('1.1.1.1')
        expect(::Naf::Machine.machine_ip_address).to eq('1.1.1.1')
      end
    end

    describe "#hostname" do
      it "return the correct ip address" do
        allow(Socket).to receive(:gethostname).and_raise(StandardError)
        expect(::Naf::Machine.hostname).to eq('local')
      end

      it "return the correct ip address" do
        allow(Socket).to receive(:gethostname).and_return('test.local')
        expect(::Naf::Machine.hostname).to eq('test.local')
      end
    end

    describe "#local_machine" do
      before do
        allow(::Naf::Machine).to receive(:machine_ip_address).and_return('1.1.1.1')
      end

      it "return the correct machine" do
        machine.update_attributes!(server_address: '1.1.1.1')
        expect(::Naf::Machine.local_machine).to eq(machine)
      end

      it "return no machines" do
        expect(::Naf::Machine.local_machine).to eq(nil)
      end
    end

    describe "#current" do
      before do
        allow(::Naf::Machine).to receive(:local_machine).and_return(machine)
      end

      it "return the correct machine" do
        expect(::Naf::Machine.current).to eq(machine)
      end
    end

    describe "#last_time_schedules_were_checked" do
      before do
        machine.last_checked_schedules_at = Time.zone.now
        machine.save!
        FactoryGirl.create(:machine_two, last_checked_schedules_at: Time.zone.now - 5.minutes)
      end

      it "return the correct machine" do
        expect(::Naf::Machine.last_time_schedules_were_checked.to_i).to eq(machine.last_checked_schedules_at.to_i)
      end
    end

    describe "#is_it_time_to_check_schedules?" do
      let!(:time) { Time.zone.now }

      it "return the correct ip address" do
        allow(::Naf::Machine).to receive(:last_time_schedules_were_checked).and_return(time)
        expect(::Naf::Machine.is_it_time_to_check_schedules?(1.minute)).to eq(false)
      end

      it "return true when last checked is nil" do
        allow(::Naf::Machine).to receive(:last_time_schedules_were_checked).and_return(nil)
        expect(::Naf::Machine.is_it_time_to_check_schedules?(time)).to eq(true)
      end
    end

    #-------------------------
    # *** Instance Methods ***
    #+++++++++++++++++++++++++

    describe "#to_s" do
      it "parse the machine correctly" do
        expect(machine.to_s).to eq("::Naf::Machine<ENABLED, id: #{machine.id}, address: 0.0.0.1, " +
          "pool size: 5, last checked schedules: , last seen: >")
      end
    end

    describe "#correct_server_address?" do
      it "return 0 for valid ip address" do
        expect(machine.correct_server_address?).to eq(0)
      end

      it "return nil for invalid ip address" do
        machine.server_address = '1.1'
        expect(machine.correct_server_address?).to be false
      end
    end

    describe "#mark_checked_schedule" do
      before do
        Timecop.freeze(Time.zone.now)
      end

      after do
        Timecop.return
      end

      it "change last_checked_schedules_at" do
        expect {
          machine.mark_checked_schedule
        }.to change(machine, :last_checked_schedules_at).
        from(nil).to(Time.zone.now)
      end
    end

    describe "#mark_alive" do
      before do
        Timecop.freeze(Time.zone.now)
      end

      after do
        Timecop.return
      end

      it "change last_seen_alive_at" do
        expect {
          machine.mark_alive
        }.to change(machine, :last_seen_alive_at).
        from(nil).to(Time.zone.now)
      end
    end

    describe "#mark_up" do
      before do
        machine.update_attributes!(marked_down: true)
        Timecop.freeze(Time.zone.now)
      end

      after do
        Timecop.return
      end

      it "change marked_down" do
        expect {
          machine.mark_up
        }.to change(machine, :marked_down).
        from(true).to(false)
      end
    end

    describe "#mark_down" do
      let!(:machine2) { FactoryGirl.create(:machine) }
      before do
        machine.mark_down(machine2)
      end

      it "set marked_down to true" do
        expect(machine.marked_down).to eq(true)
      end

      it "set marked_down_by_machine_id" do
        expect(machine.marked_down_by_machine_id).to eq(machine2.id)
      end

      it "change marked_down_at to timestamp" do
        expect(machine.marked_down_at).to be_within(3.seconds).of(Time.zone.now)
      end
    end

    describe "#is_stale?" do
      it "return true when machine is stale" do
        machine.last_seen_alive_at = Time.zone.now - 1.minute
        expect(machine.is_stale?(1.second)).to eq(true)
      end

      it "return false when machine is not stale" do
        machine.last_seen_alive_at = Time.zone.now
        expect(machine.is_stale?(1.minute)).to eq(false)
      end

      it "return false when the runner hasn't been started" do
        machine.last_seen_alive_at = nil
        expect(machine.is_stale?(1.second)).to eq(false)
      end
    end

    describe "#mark_processes_as_dead" do
      before(:all) do
        Timecop.freeze(Time.zone.now)
      end

      after(:all) do
        Timecop.return
      end

      let!(:running_job) {
        FactoryGirl.create(:running_job_base, created_at: Time.zone.now - 1.minute, started_on_machine_id: machine.id)
      }

      before do
        machine.mark_processes_as_dead(machine)
        running_job.reload
        running_job.historical_job.reload
      end

      it "set request_to_terminate to true" do
        expect(running_job.request_to_terminate).to eq(true)
      end

      it "set marked_dead_by_machine_id to the machine's id" do
        expect(running_job.marked_dead_by_machine_id).to eq(machine.id)
      end

      it "set marked_dead_at to the current time" do
        expect(running_job.marked_dead_at).to be_within(3.seconds).of(Time.zone.now)
      end

      it "mark the job as finished" do
        expect(running_job.historical_job.finished_at).to be_within(3.seconds).of(Time.zone.now)
      end
    end

    describe "#mark_machine_down" do
      before(:all) do
        Timecop.freeze(Time.zone.now)
      end

      after(:all) do
        Timecop.return
      end

      before do
        machine.mark_machine_down(machine)
      end

      it "set marked_down to true" do
        expect(machine.marked_down).to eq(true)
      end

      it "set marked_down_by_machine_id to the machine's id" do
        expect(machine.marked_down_by_machine_id).to eq(machine.id)
      end

      it "set marked_down_at to the current time" do
        expect(machine.marked_down_at).to be_within(3.seconds).of(Time.zone.now)
      end
    end

    describe "#affinity" do
      let!(:classification) { FactoryGirl.create(:machine_affinity_classification) }
      it "return affinity associated with machine's id" do
        affinity = FactoryGirl.create(:affinity,
                                      id: 4,
                                      affinity_classification_id: classification.id,
                                      affinity_name: machine.id.to_s)
        expect(machine.affinity).to eq(affinity)
      end

      it "nil when there's no affinity associated with machine's id" do
        expect(machine.affinity).to eq(nil)
      end
    end

    describe "#short_name_if_it_exist" do
      it "return short name" do
        machine.short_name = 'Machine1'
        expect(machine.short_name_if_it_exist).to eq('Machine1')
      end

      it "return server name" do
        machine.short_name = nil
        machine.server_name = 'machine.example.com'
        expect(machine.short_name_if_it_exist).to eq('machine.example.com')
      end
    end

  end
end
