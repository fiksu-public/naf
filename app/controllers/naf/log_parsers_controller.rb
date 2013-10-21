module Naf
  class LogParsersController < Naf::ApplicationController

    def logs
      success = false
      if params['naf_job_id'].present?
        response = ::Logical::Naf::LogParser::Job.new(params).logs
        success = true
      elsif params['record_type'] == 'machine'
        response = ::Logical::Naf::LogParser::Machine.new(params).logs
        success = true
      elsif params['record_type'] == 'runner'
        response = ::Logical::Naf::LogParser::Runner.new(params).logs
        success = true
      end

      render json: "convertToJsonCallback(" + { success: success }.merge(response).to_json + ")"
    end

  end
end
