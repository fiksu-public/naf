require 'spec_helper'

module Naf
  describe ApplicationsController  do

    it "should respond with the index action" do
      ::Logical::Naf::Application.should_not_receive(:all).and_return([])
      get :index
      response.should render_template("naf/applications/index")
      response.should be_success
    end

    it "should respond with show action" do
      id = 5
      Application.should_receive(:find).with("5").and_return(nil)
      get :show, :id => id
      response.should render_template("naf/record")
      response.should be_success
    end

    context "with regard to the edit action" do

      it "should build a new application schedule if it was destroyed" do
        @id = 5
        app_mock = mock_model(Application)
        Application.should_receive(:find).with("5").and_return(app_mock)
        app_mock.should_receive(:application_schedule).and_return(nil)
        app_mock.should_receive(:build_application_schedule).and_return(nil)
      end

      it "should respond without building a new application schedule" do
        @id = 5
        app_mock = mock_model(Application)
        schedule_mock = mock_model(ApplicationSchedule) 
        app_mock.should_receive(:application_schedule).and_return(schedule_mock)
        Application.should_receive(:find).with("5").and_return(app_mock)
        app_mock.should_not_receive(:build_application_schedule)
      end

      after(:each) do
        get :edit, :id => @id
        response.should render_template("naf/applications/edit")
        response.should be_success

      end
    end

    it "should respond with affinity new" do
      app = mock('app')
      Application.should_receive(:new).and_return(app)
      app.should_receive(:build_application_schedule).and_return(nil)
      get :new
      response.should render_template("naf/applications/new")
      response.should be_success
    end
    
    context "on the create action" do
      let(:valid_app)        { mock_model(Application, :save => true, :id => 5)  }
      let(:invalid_app)      { mock_model(Application, :save => false) }
      it "should redirect to show when valid" do
        Application.should_receive(:new).and_return(valid_app)
        post :create, :application =>{}
        response.should redirect_to(application_path(valid_app.id))
      end
      it "should re-render to new when invalid" do
        Application.should_receive(:new).and_return(invalid_app)
        post :create, :application => {}
        response.should render_template("naf/applications/new")
      end
    end

    context "on the updated action" do
      let(:valid_app)   { mock_model(Application, :update_attributes => true, :id => 5) }
      let(:invalid_app) { mock_model(Application, :update_attributes => false,:id => 5) }
     
      it "should redirect to show when valid" do
        Application.should_receive(:find).with("5").and_return(valid_app)
        post :update, :id => 5, :application =>{}
        response.should redirect_to(application_path(valid_app.id))
      end
      it "should re-render to new when invalid" do
        Application.should_receive(:find).and_return(invalid_app)
        post :update, :id => 5, :application => {}
        response.should render_template("naf/applications/edit")
      end
    end

    # Ensure that some instance variables are set
    after(:each) do
      cols = assigns(:cols)
      attributes = assigns(:attributes)
    end
  
  

    
  end
end
