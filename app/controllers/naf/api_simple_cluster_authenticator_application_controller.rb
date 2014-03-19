module Naf
  class ApiSimpleClusterAuthenticatorApplicationController < ActionController::Base

    def naf_cookie_valid?
      ::Logical::Naf::UserSession.new(session[::Naf.configuration.api_domain_cookie_name]).valid?
    end

  end
end
