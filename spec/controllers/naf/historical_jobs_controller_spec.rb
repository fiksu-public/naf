require 'spec_helper'

module Naf
  describe HistoricalJobsController do
    it "should respond with the index action" do
      get :index
      expect(response).to render_template("naf/historical_jobs/index")
      expect(response).to be_success
    end

    it "should respond with the show action" do
      id = 5
      expect(Naf::HistoricalJob).to receive(:find).with("5").and_return(nil)
      expect(Logical::Naf::Job).to receive(:new).and_return(nil)
      get :show, id: id
      expect(response).to be_success
    end
  end
end
