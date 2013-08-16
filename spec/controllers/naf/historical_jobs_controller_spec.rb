require 'spec_helper'

module Naf
  describe HistoricalJobsController do
    it "should respond with the index action" do
      get :index
      response.should render_template("naf/historical_jobs/index")
      response.should be_success
    end

    it "should respond with the show action" do
      id = 5
      Naf::HistoricalJob.should_receive(:find).with("5").and_return(nil)
      Logical::Naf::Job.should_receive(:new).and_return(nil)
      get :show, id: id
      response.should be_success
    end
  end
end
