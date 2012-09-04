require 'spec_helper'

module Naf
  describe ApplicationsController  do

    it "should respond with the index action" do
      ::Logical::Naf::Application.should_receive(:all).and_return([])
      get :index
      response.should render_template("naf/datatable")
      response.should be_success
    end

    it "should respond with show action" do
      id = 5
      Application.should_receive(:find).with("5").and_return(nil)
      get :show, :id => id
      response.should render_template("naf/record")
      response.should be_success
    end

    it "should respond with edit action" do
      id = 5
      Application.should_receive(:find).with("5").and_return(nil)
      get :edit, :id => id
      response.should render_template("naf/applications/edit")
      response.should be_success
    end

    it "should respond with affinity new" do
      app = mock('app')
      Application.should_receive(:new).and_return(app)
      app.should_receive(:build_application_schedule).and_return(nil)
      get :new
      response.should render_template("naf/applications/new")
      response.should be_success
    end

    context "on the destroy action" do
      let(:app) { mock_model(Application, :id => 5) }
      it "should destroy record and redirect to the index" do
        Application.should_receive(:find).with("5").and_return(app)
        app.should_receive(:destroy).and_return(true)
        delete :destroy, {:id => "5"}
        response.should redirect_to(applications_path)
      end
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
