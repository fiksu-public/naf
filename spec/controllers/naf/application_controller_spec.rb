require 'spec_helper'

module Naf
  describe ApplicationController do
    it "should inherit from specified controller" do
      ApplicationController.superclass.should == Naf.controller_class
    end
  end

end
