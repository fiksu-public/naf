require 'spec_helper'

module Naf
  describe HistoricalJobAffinityTabsController do
    let(:model_class) { HistoricalJobAffinityTab }

    it "should respond with index action nested under a job" do
      expect(model_class).to receive(:where).with({ historical_job_id: "1" }).and_return([])
      get :index, historical_job_id: 1
      expect(response).to render_template("naf/datatable")
      expect(response).to be_success
    end

    it "should respond with the show action" do
      expect(HistoricalJob).to receive(:find).with("1").and_return(nil)
      expect(model_class).to receive(:find).with("5").and_return(nil)
      get :show, id: 5, historical_job_id: 1
      expect(response).to render_template("naf/record")
      expect(response).to be_success
    end

    it "should respond with the edit action" do
      expect(HistoricalJob).to receive(:find).with("1").and_return(nil)
      expect(model_class).to receive(:find).with("5").and_return(nil)
      get :edit, id: 5, historical_job_id: 1
      expect(response).to render_template("naf/historical_job_affinity_tabs/edit")
      expect(response).to be_success
    end

    it "should respond with the new action" do
      expect(HistoricalJob).to receive(:find).with("1").and_return(nil)
      expect(model_class).to receive(:new).and_return(nil)
      get :new, historical_job_id: 1
      expect(response).to render_template("naf/historical_job_affinity_tabs/new")
      expect(response).to be_success
    end

    context "on the create action" do
      let(:valid_tab) { mock_model(model_class, save: true, id: 5, historical_job_id: 1) }
      let(:invalid_tab) { mock_model(model_class, save: false) }
      let(:job) { mock_model(HistoricalJob, id: 1)  }

      subject do
        post :create, job_affinity_tab: { historical_job_id: 1 }, historical_job_id: 1
      end

      before do
        expect(HistoricalJob).to receive(:find).with("1").and_return(job)
      end

      it "should redirect to show when valid" do
        expect(model_class).to receive(:new).and_return(valid_tab)
        allow(valid_tab).to receive(:affinity_name).and_return("Test Name")
        path = historical_job_historical_job_affinity_tab_path(job, valid_tab)
        expect(subject).to redirect_to(path)
      end
      it "should re-render to new when invalid" do
        expect(model_class).to receive(:new).and_return(invalid_tab)
        expect(subject).to render_template("naf/historical_job_affinity_tabs/new")
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
        expect(HistoricalJob).to receive(:find).with("1").and_return(job)
      end

      it "should redirect to show when valid" do
        expect(model_class).to receive(:find).and_return(valid_job)
        allow(valid_job).to receive(:affinity_name).and_return("Test Name")
        path = historical_job_historical_job_affinity_tab_path(job, valid_job)
        expect(subject).to redirect_to(path)
      end
      it "should re-render to edit  when invalid" do
        expect(model_class).to receive(:find).and_return(invalid_job)
        expect(subject).to render_template("naf/historical_job_affinity_tabs/edit")
      end

    end

    # Ensure that some instance variables are set
    after do
      cols = assigns(:cols)
      attributes = assigns(:attributes)
    end

  end
end
