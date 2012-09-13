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

    context "with respect to json post requests" do
      context "with an application_id request parameter" do
       
        it "should create a valid job when the application has a schedule"
        
        it "should create a valid job when the application doesn't have a schedule"
       
      end

      context "without an application_id request parameter" do
        
        it "should create a valid job"

      end
    end

    # Ensure that some instance variables are set
    after(:each) do
      cols = assigns(:cols)
      attributes = assigns(:attributes)
    end
  
  end
end
