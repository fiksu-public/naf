require 'spec_helper'

module Naf
  describe ApplicationController do
    it "should inherit from specified controller" do
      ApplicationController.superclass.should == Naf.ui_controller_class
    end
  end

end
