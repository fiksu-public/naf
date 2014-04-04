module Naf
  class LogViewerController < Naf::ApplicationController

  	def index
       if params['record_type'] == 'job'
        @job = ::Naf::HistoricalJob.find_by_id(params['record_id'].to_i)
        @status = ::Logical::Naf::Job.new(@job).status
        @partial = 'job_logs'
      elsif params['record_type'] == 'runner'
        @runner = ::Naf::MachineRunner.find_by_id(params['record_id'].to_i)
        @partial = 'runner_logs'
      end
    end

  end
end
