require 'spec_helper'

module Naf
  describe JobsController do
    
    it "should respond with the index action" do
      Logical::Naf::Job.should_not_receive(:all).and_return([])
      get :index
      response.should render_template("naf/datatable")
      response.should be_success
    end

    it "should respond with the show action" do
      id = 5
      Naf::Job.should_receive(:find).with("5").and_return(nil)
      Logical::Naf::Job.should_receive(:new).and_return(nil)
      get :show, :id => id
      response.should render_template("naf/record")
      response.should be_success
    end

    # Ensure that some instance variables are set
    after(:each) do
      cols = assigns(:cols)
      attributes = assigns(:attributes)
    end
  
  end
end
