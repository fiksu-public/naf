module Naf
  class LogParsersController < Naf::ApplicationController

    def logs
      response = params['logical_type'].constantize.new(params).logs
      if response.present?
        success = true
      else
        success = false
      end

      render json: "convertToJsonCallback(" + { success: success }.merge(response).to_json + ")"
    end

  end
end
