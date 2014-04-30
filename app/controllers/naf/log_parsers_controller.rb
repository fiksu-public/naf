module Naf
  class LogParsersController < Naf::ApiSimpleClusterAuthenticatorApplicationController

    def logs
      if naf_cookie_valid?
        if params['record_id'].present?
          response = params['logical_type'].constantize.new(params).logs

          if response.present?
            success = true
          else
            success = false
          end
        else
          response = {
            logs: '&nbsp;&nbsp;<span>Record id is not present</br></span>'
          }
          success = false
        end

        render json: "convertToJsonCallback(" + { success: success }.merge(response).to_json + ")"
      else
        render json: "convertToJsonCallback(" + { success: false }.to_json + ")"
      end
    end

  end
end
