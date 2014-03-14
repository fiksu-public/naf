module Naf
  class ApplicationController < Naf.ui_controller_class
    layout Naf.layout

    require 'will_paginate/array'

    protect_from_forgery

    before_filter :check_naf_cookie_presence

    protected

    # Sets current rows_per_page direction from cookies or params.
    def set_rows_per_page
      if params[:iDisplayLength].present?
        @rows_per_page = (params[:iDisplayLength] or "20").to_i
      elsif cookies[:iDisplayLength].present?
        @rows_per_page = cookies[:iDisplayLength].to_i
      else
        @rows_per_page = 20
      end
      cookies[:iDisplayLength] = @rows_per_page
    end

    # Sets current page
    def set_page
      @page = (params[:iDisplayStart] ? ( params[:iDisplayStart].to_i / @rows_per_page ) + 1 : 1)
    end

    def set_search_status
      @search_status = cookies[:search_status]
    end

    # Sets current search status
    def set_status
      status = params[:search][:status]
      if status.present?
        @search_status = status.to_sym
      else
        @search_status = :all
      end
      cookies[:search_status] = @search_status
    end

    private

    def check_naf_cookie_presence
      user_session = ::Logical::Naf::UserSession.new(cookies[domain_cookie_name])
      if !user_session.valid?
        cookies.delete(domain_cookie_name)
        cookies[domain_cookie_name] = user_session.token_cookie
      end
    end

    def domain_cookie_name
      @domain_cookie_name ||= ::Naf.configuration.api_domain_cookie_name
    end

  end
end
