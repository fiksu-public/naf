require 'spec_helper'

module Logical
  module Naf
    describe Job do

      TIME_DISPLAY_REGEX = /^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2} (AM|PM)$/

      STATUS_MAP = {
        job: "Queued",
        canceled_job: "Terminated",
        terminating_job: "Terminating",
        running_job: "Running",
        failed_to_start_job: "Failed to Start",
        finished_job: "Finished",
        job_with_error: "Error 1",
        job_with_signal: "Signaled 1"
      }

      let!(:job) { Job.new(FactoryGirl.create(:finished_job)) }
      let!(:historical_job) { job.instance_variable_get(:@job) }

      it "should return the correct statuses" do
        STATUS_MAP.each do |job_type, expected_status|
          logical_job = Job.new(FactoryGirl.create(job_type))
          logical_job.status.should eql(expected_status)
        end
      end

      context "#title" do
        let(:scheduled_job) { Job.new(FactoryGirl.create(:scheduled_job)) }

        context "for a job scheduled from an application" do
          it "should get the title from the application_schedule" do
            scheduled_job.title.should eql(scheduled_job.application.title)
          end
        end

        context "for an ad hoc job" do
          it "should get the title, formed from its command" do
            job = Job.new(FactoryGirl.create(:job, command: "Yo"*30))
            job.title.should eql(job.command)
          end
        end
      end

      context "with regard to the timestamps" do
        it "should display started_at nicely" do
          job.started_at.should be_a(String)
          job.started_at.should =~ /-0h3m/
        end

        it "should display finished_at nicely" do
          job.finished_at.should be_a(String)
          job.finished_at.split(',').first.should =~ /ago$/
        end

        it "should display queued time explicitly as string" do
          job.queued_time.should be_a(String)
          job.queued_time.should =~ TIME_DISPLAY_REGEX
        end
      end

      context "#to_detailed_hash" do
        let(:detailed_hash) { Job.new(FactoryGirl.create(:finished_job)).to_detailed_hash }

        it "should display started_at, and finished_at explicitly as a string" do
          [:started_at, :finished_at].each do |timestamp|
            detailed_hash[timestamp].should be_a String
            detailed_hash[timestamp].should =~ TIME_DISPLAY_REGEX
          end
        end
      end

      context "#to_hash" do
        let(:columns) {
          [:id,
           :server,
           :pid,
           :queued_time,
           :title,
           :started_at,
           :finished_at,
           :run_time,
           :affinities,
           :tags,
           :status] }

        it "should have the following columns" do
          job.to_hash.keys.should. == columns
        end
      end

      context "#search" do
        before(:all) do
          ::Naf::HistoricalJob.delete_all
          @job_status_type_map = {}
          STATUS_MAP.each{ |factory, status|
            @job_status_type_map[status.downcase.split(' ').join('_')] = Job.new(FactoryGirl.create(factory))
          }
        end

        it "should filter by status correctly" do
          @job_status_type_map.each do |status, logical_job|
            Job.search(status: status, limit: 10).map(&:id).should include(logical_job.id)
          end
        end

        it "should not filter by status when 'all' is specified" do
          job_ids = @job_status_type_map.values.map(&:id)
          result_ids = Job.search(status: 'all', limit: 10).map(&:id)
          job_ids.each do |job_id|
            result_ids.should include job_id
          end
        end

        context "for other filtering and searching" do
          let(:job_one) { FactoryGirl.create(:running_job,
                                             pid: 400,
                                             command: "MyScript.run --thing friend") }
          let(:job_two) { FactoryGirl.create(:running_job,
                                             application_type: FactoryGirl.create(:bash_command_app_type),
                                             pid: 500,
                                             command: "ps aux | grep ssh",
                                             priority: 5,
                                             application_run_group_restriction: FactoryGirl.create(:limited_per_machine),
                                             application_run_group_name: "crazy group") }

          before do
            ::Naf::HistoricalJob.delete_all
            job_one
            job_two
            ::Naf::HistoricalJob.all.should have(2).items
          end

          it "should filter by application type" do
            id_one = job_one.application_type_id
            Job.search(application_type_id: id_one, limit: 10).map(&:id).should == [job_one.id]
            id_two = job_two.application_type_id
            Job.search(application_type_id: id_two, limit: 10).map(&:id).should == [job_two.id]
          end

          it "should filter by run_group_restriction" do
            id_one = job_one.application_run_group_restriction_id
            Job.search(application_run_group_restriction_id: id_one, limit: 10).map(&:id).should == [job_one.id]
            id_two = job_two.application_run_group_restriction_id
            Job.search(application_run_group_restriction_id: id_two, limit: 10).map(&:id).should == [job_two.id]
          end

          it "should filter by priority" do
            priority_one = job_one.priority
            Job.search(priority: priority_one, limit: 10).map(&:id).should == [job_one.id]
            priority_two = job_two.priority
            Job.search(priority: priority_two, limit: 10).map(&:id).should == [job_two.id]
          end

          it "should filter by pid" do
            pid_one = job_one.pid
            Job.search(pid: pid_one, limit: 10).map(&:id).should == [job_one.id]
            pid_two = job_two.pid
            Job.search(pid: pid_two, limit: 10).map(&:id).should == [job_two.id]
          end

          it "should find jobs where the command is like the query" do
            Job.search(command: "friend", limit: 10).map(&:id).should == [job_one.id]
            Job.search(command: "ssh", limit: 10).map(&:id).should == [job_two.id]
          end

          it "should find jobs where the application_run_group_name is like the query" do
            Job.search(application_run_group_name: "crazy", limit: 10).map(&:id).should == [job_two.id]
          end
        end
      end

      describe "#get_job_scope" do
        before do
          ::Naf::HistoricalJob.delete_all
        end
        let!(:finished_job) { FactoryGirl.create(:finished_job) }

        it "return correct job when scope is specified" do
          ::Logical::Naf::Job.get_job_scope({ status: :finished }).should == [finished_job]
        end

        it "return correct jobs when scope is not specified" do
          historical_job = FactoryGirl.create(:job)
          ::Logical::Naf::Job.get_job_scope({}).should == [finished_job, historical_job]
        end
      end

      describe "#run_time" do
        before do
          Timecop.freeze(Time.zone.now)
        end

        after do
          Timecop.return
        end

        it "show correct run time when job has finished" do
          historical_job.started_at = Time.zone.now - 6.seconds
          historical_job.finished_at = Time.zone.now
          job.run_time.should == '0h0m6s'
        end

        describe "show correct run time when job is running" do
          it "less than 2 days" do
            historical_job.started_at = Time.zone.now - 3.hours
            historical_job.finished_at = nil
            job.run_time.should == '3h0m0s'
          end

          it "more than 2 days" do
            historical_job.started_at = Time.zone.now - 3.days
            historical_job.finished_at = nil
            job.run_time.should == '3d0h0m0s'
          end
        end

        it "show correct run time when job has not started" do
          historical_job.started_at = nil
          historical_job.finished_at = nil
          job.run_time.should == ''
        end
      end

      describe "#started_at" do
        before do
          Timecop.freeze(Time.zone.now)
        end

        after do
          Timecop.return
        end

        it "show correct run time when job has started < 60 seconds ago" do
          historical_job.started_at = Time.zone.now - 10.seconds
          job.started_at.should =~ /10 seconds ago/
        end

        it "show correct run time when job has started >= 60 seconds and < 2 days ago" do
          historical_job.started_at = Time.zone.now - 6.hours
          job.started_at.should =~ /-6h0m/
        end

        it "show correct run time when job has started <= 2 days ago" do
          historical_job.started_at = Time.zone.now - 3.days
          job.started_at.should =~ /3 days ago/
        end
      end

      describe "#finished_at" do
        before do
          Timecop.freeze(Time.zone.now)
        end

        after do
          Timecop.return
        end

        it "show correct run time when job has finished" do
          historical_job.finished_at = Time.zone.now - 3.seconds
          job.finished_at.should =~ /less than 5 seconds ago/
        end

        it "show correct run time when job has not finished" do
          historical_job.finished_at = nil
          job.finished_at.should == ''
        end
      end

      describe "#tags" do
        it "show custom visible tags" do
          historical_job.tags = '{test}'
          job.tags.should == 'test'
        end

        it "not show system or custom invisible tags" do
          historical_job.tags = '{$test,_test}'
          job.tags.should == ''
        end

        it "return nil when tags is not present" do
           job.tags.should == nil
        end
      end

    end
  end
end
