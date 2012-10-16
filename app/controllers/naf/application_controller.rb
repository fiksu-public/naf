module Naf
  class ApplicationController < Naf.controller_class
    layout Naf.layout

    require 'will_paginate/array'

    protect_from_forgery

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
  end
end
