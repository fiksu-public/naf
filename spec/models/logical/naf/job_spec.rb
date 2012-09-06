require 'spec_helper'

module Logical
  module Naf
    describe Job do
    
      TIME_DISPLAY_REGEX = /^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2} (AM|PM)$/

      STATUS_MAP = {
        :job => "Queued", :canceled_job => "Canceled", :running_job => "Running",
        :failed_to_start_job => "Failed to Start", :finished_job => "Finished", 
        :job_with_error => "Error"
      }

      it "should return the correct statuses" do
        STATUS_MAP.each do |job_type, expected_status|
          logical_job = Job.new(FactoryGirl.create(job_type))
          logical_job.status.should eql(expected_status)
        end
      end

      context "with regard to title" do
        let(:scheduled_job) { Job.new(FactoryGirl.create(:scheduled_job)) }
        let(:job)           { Job.new(FactoryGirl.create(:job, :command => "Yo"*30)) }

        context "for a job scheduled from an application" do
          it "should get the title from the application_schedule" do
            scheduled_job.title.should eql(scheduled_job.application.application_schedule.title)
          end
        end
        context "for an ad hoc job" do
          it "should get the title, truncated from its command" do
            job.title.should eql(job.truncate(job.command))
          end
        end

      end

      context "with regard to the timestamps" do
        let(:job) { Job.new(FactoryGirl.create(:finished_job)) }
        it "should display started_at nicely" do
          job.started_at.should be_a(String)
          job.started_at.should =~ /ago$/
        end
        it "should display finished_at nicely" do
          job.finished_at.should be_a(String)
          job.finished_at.should =~ /ago$/
        end
        it "should display queued time explicitly as string" do
          job.queued_time.should be_a(String)
          job.queued_time.should =~ TIME_DISPLAY_REGEX
        end
      end

      context "with regard to the detailed_hash" do
        let(:detailed_hash) { Job.new(FactoryGirl.create(:finished_job)).to_detailed_hash }
        it "should display started_at, and finished_at explicitly as a string" do
          [:started_at, :finished_at].each do |timestamp|
            detailed_hash[timestamp].should be_a String
            detailed_hash[timestamp].should =~ TIME_DISPLAY_REGEX
          end
        end
      end

      context "with regard to the to_hash" do
        let(:job) { Job.new(FactoryGirl.create(:finished_job)) }
        before(:all) do
          @columns = [:id, :server, :pid, :queued_time, :title, :started_at, :finished_at, :status]
        end
        it "should have the following columns" do
          job.to_hash.keys.should eql(@columns)
        end
      end

      context "with regard to the search" do
        
        before(:all) do
          # (nlim) Aliasing bug doeosn't allow me to do this
          #::Naf::Job.destroy_all
          @job_status_type_map = {}
          STATUS_MAP.each{ |factory, status| 
            @job_status_type_map[status.downcase.split(' ').join('_')] = Job.new(FactoryGirl.create(factory))
          }
        end
        
        it "should filter by status correctly" do
          @job_status_type_map.each do |status, logical_job|
            Job.search(:status => status).map(&:id).should include(logical_job.id)
            # I really want to do this, once I'm able to clear all the jobs
            # Job.search(:status => status).map(&:id).should equal([logical_job.id])
          end
        end
        
        it "should not filter by status when 'all' is specified" do
          job_ids = @job_status_type_map.values.map(&:id)
          result_ids = Job.search(:status => 'all').map(&:id)
          job_ids.each do |job_id|
            result_ids.should include job_id
          end
        end
        
        context "for other filtering" do

          # (nlim) These are the only fields the job search
          # should filter by
          
          it "should filter by application type"
          
          it "should filter by run_group_restriction"
          
          it "should filter by priority"
          
          it "should filter by pid"
          
        end
        
        context "for search fields" do
          
          it "should find jobs where the command is like the query"

          it "should find jobs where the application_run_group_name is like the query"

        end
      end

    end
  end
end
