require 'spec_helper'

module Naf
  describe JobAffinityTabsController do
    
    let(:model_class) { JobAffinityTab }
    
    it "should respond with index action nested under a job" do
      model_class.should_receive(:where).with({:job_id => "1"}).and_return([])
      get :index, :job_id => 1
      response.should render_template("naf/datatable")
      response.should be_success
    end

    it "should respond with the show action" do
      Job.should_receive(:find).with("1").and_return(nil)
      model_class.should_receive(:find).with("5").and_return(nil)
      get :show, :id => 5, :job_id => 1
      response.should render_template("naf/record")
      response.should be_success
    end

    it "should respond with the destroy action and redirect to nested index" do
      tab = mock_model(model_class, :job_id => 1, :id => 5)
      job = mock_model(Job, :id => 1)
      Job.should_receive(:find).with("1").and_return(job)
      model_class.should_receive(:find).with("5").and_return(tab)
      tab.stub!(:affinity_name).and_return("Test Name")
      delete :destroy, :id => 5, :job_id => 1
      index_path = job_job_affinity_tabs_path(job)
      response.should redirect_to(index_path)
    end
    
    it "should respond with the edit action" do
      Job.should_receive(:find).with("1").and_return(nil)
      model_class.should_receive(:find).with("5").and_return(nil)
      get :edit, :id => 5, :job_id => 1
      response.should render_template("naf/job_affinity_tabs/edit")
      response.should be_success
    end
    
    it "should respond with the new action" do
      Job.should_receive(:find).with("1").and_return(nil)
      model_class.should_receive(:new).and_return(nil)
      get :new, :job_id => 1
      response.should render_template("naf/job_affinity_tabs/new")
      response.should be_success
    end

    context "on the create action" do
      let(:valid_tab)   { mock_model(model_class, :save => true, :id => 5,:job_id => 1)}
      let(:invalid_tab) { mock_model(model_class, :save => false) }
      let(:job) { mock_model(Job, :id => 1)  }

      subject do 
        post :create, :job_affinity_tab => {:job_id => 1}, :job_id => 1
      end

      before(:each) do
        Job.should_receive(:find).with("1").and_return(job)
      end

      it "should redirect to show when valid" do
        model_class.should_receive(:new).and_return(valid_tab)
        valid_tab.stub!(:affinity_name).and_return("Test Name")
        path = job_job_affinity_tab_path(job, valid_tab)
        subject.should redirect_to(path)
      end
      it "should re-render to new when invalid" do
        model_class.should_receive(:new).and_return(invalid_tab)
        subject.should render_template("naf/job_affinity_tabs/new")
      end
    end

    context "on the update action" do
      let(:valid_job)   { mock_model(model_class, :update_attributes => true, :id => 5, :job_id => 1)  }
      let(:invalid_job) { mock_model(model_class, :update_attributes => false, :id => 5, :job_id => 1) }
      let(:job) { mock_model(Job, :id => 1)  }
      
      subject do 
        put :update, :job_affinity_tab => {:job_id => 1}, :id => 5, :job_id => 1
      end
      
      before(:each) do
        Job.should_receive(:find).with("1").and_return(job)
      end

      it "should redirect to show when valid" do
        model_class.should_receive(:find).and_return(valid_job)
        valid_job.stub!(:affinity_name).and_return("Test Name")
        path = job_job_affinity_tab_path(job, valid_job)
        subject.should redirect_to(path)
      end
      it "should re-render to edit  when invalid" do
        model_class.should_receive(:find).and_return(invalid_job)
        subject.should render_template("naf/job_affinity_tabs/edit")
      end

    end

    # Ensure that some instance variables are set
    after(:each) do
      cols = assigns(:cols)
      attributes = assigns(:attributes)
    end
  
    
    
  end
end

