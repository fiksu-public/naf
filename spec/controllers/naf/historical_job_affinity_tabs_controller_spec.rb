require 'spec_helper'

module Naf
  describe HistoricalJobAffinityTabsController do
    let(:model_class) { HistoricalJobAffinityTab }

    it "should respond with index action nested under a job" do
      model_class.should_receive(:where).with({ historical_job_id: "1" }).and_return([])
      get :index, historical_job_id: 1
      response.should render_template("naf/datatable")
      response.should be_success
    end

    it "should respond with the show action" do
      HistoricalJob.should_receive(:find).with("1").and_return(nil)
      model_class.should_receive(:find).with("5").and_return(nil)
      get :show, id: 5, historical_job_id: 1
      response.should render_template("naf/record")
      response.should be_success
    end

    it "should respond with the edit action" do
      HistoricalJob.should_receive(:find).with("1").and_return(nil)
      model_class.should_receive(:find).with("5").and_return(nil)
      get :edit, id: 5, historical_job_id: 1
      response.should render_template("naf/historical_job_affinity_tabs/edit")
      response.should be_success
    end

    it "should respond with the new action" do
      HistoricalJob.should_receive(:find).with("1").and_return(nil)
      model_class.should_receive(:new).and_return(nil)
      get :new, historical_job_id: 1
      response.should render_template("naf/historical_job_affinity_tabs/new")
      response.should be_success
    end

    context "on the create action" do
      let(:valid_tab) { mock_model(model_class, save: true, id: 5, historical_job_id: 1) }
      let(:invalid_tab) { mock_model(model_class, save: false) }
      let(:job) { mock_model(HistoricalJob, id: 1)  }

      subject do 
        post :create, job_affinity_tab: { historical_job_id: 1 }, historical_job_id: 1
      end

      before do
        HistoricalJob.should_receive(:find).with("1").and_return(job)
      end

      it "should redirect to show when valid" do
        model_class.should_receive(:new).and_return(valid_tab)
        valid_tab.stub!(:affinity_name).and_return("Test Name")
        path = historical_job_historical_job_affinity_tab_path(job, valid_tab)
        subject.should redirect_to(path)
      end
      it "should re-render to new when invalid" do
        model_class.should_receive(:new).and_return(invalid_tab)
        subject.should render_template("naf/historical_job_affinity_tabs/new")
      end
    end

    context "on the update action" do
      let(:valid_job) { mock_model(model_class, update_attributes: true, id: 5, historical_job_id: 1)  }
      let(:invalid_job) { mock_model(model_class, update_attributes: false, id: 5, historical_job_id: 1) }
      let(:job) { mock_model(HistoricalJob, id: 1)  }

      subject do 
        put :update, job_affinity_tab: { historical_job_id: 1 }, id: 5, historical_job_id: 1
      end

      before do
        HistoricalJob.should_receive(:find).with("1").and_return(job)
      end

      it "should redirect to show when valid" do
        model_class.should_receive(:find).and_return(valid_job)
        valid_job.stub!(:affinity_name).and_return("Test Name")
        path = historical_job_historical_job_affinity_tab_path(job, valid_job)
        subject.should redirect_to(path)
      end
      it "should re-render to edit  when invalid" do
        model_class.should_receive(:find).and_return(invalid_job)
        subject.should render_template("naf/historical_job_affinity_tabs/edit")
      end

    end

    # Ensure that some instance variables are set
    after do
      cols = assigns(:cols)
      attributes = assigns(:attributes)
    end

  end
end
