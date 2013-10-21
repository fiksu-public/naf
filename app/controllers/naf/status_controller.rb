module Naf
  class StatusController < Naf::ApplicationController

  	def index
  		@machines = []
  		::Naf::Machine.all.each do |machine|
  			@machines << ::Logical::Naf::Machine.new(machine).status
  		end
  	end

  end
end
