module Naf
  class LogViewerController < Naf::ApplicationController

  	def index
			if params['naf_job_id'].present?
				@job = ::Naf::HistoricalJob.find_by_id(params['naf_job_id'].to_i)
				@status = ::Logical::Naf::Job.new(@job).status
				@partial = 'job_logs'
			elsif params['machine_id'].present?
				@machine = ::Naf::Machine.find_by_id(params['machine_id'].to_i)
				@partial = 'machine_logs'
			elsif params['runner_id'].present?
				@runner = ::Naf::MachineRunner.find_by_id(params['runner_id'].to_i)
				@partial = 'runner_logs'
			end
  	end

  end
end
