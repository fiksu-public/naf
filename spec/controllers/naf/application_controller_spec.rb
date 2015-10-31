require 'spec_helper'

module Naf
  describe ApplicationController do
    it "should inherit from specified controller" do
      expect(ApplicationController.superclass).to eq(Naf.ui_controller_class)
    end
  end

end
