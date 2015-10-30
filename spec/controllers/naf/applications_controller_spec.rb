require 'spec_helper'

module Naf
  describe ApplicationsController  do

    it "should respond with the index action" do
      get :index
      expect(response).to render_template("naf/applications/index")
      expect(response).to be_success
    end

    it "should respond with show action" do
      id = 5
      expect(Application).to receive(:find).with("5").and_return(nil)
      get :show, id: id
      expect(response).to be_success
    end

    context "on the create action" do
      let(:application_schedule) { mock_model(ApplicationSchedule, application_run_group_name: 'command', prerequisites: []) }
      let(:valid_app) { mock_model(Application, save: true, id: 5, update_attributes: true, application_schedule: application_schedule) }
      let(:invalid_app) { mock_model(Application, save: false, update_attributes: false, application_schedule: application_schedule) }

      it "should redirect to show when valid" do
        expect(Application).to receive(:new).and_return(valid_app)
        post :create, application: {}
        expect(response).to redirect_to(application_path(valid_app.id))
      end

      it "should re-render to new when invalid" do
        allow(invalid_app).to receive(:build_application_schedule)
        expect(Application).to receive(:new).and_return(invalid_app)
        post :create, application: {}
        expect(response).to render_template("naf/applications/new")
      end
    end

    context "on the updated action" do
      let(:valid_app) { mock_model(Application, update_attributes: true, application_schedule: nil, id: 5) }
      let(:invalid_app) { mock_model(Application, update_attributes: false, id: 5) }

      it "should redirect to show when valid" do
        expect(Application).to receive(:find).with("5").and_return(valid_app)
        post :update, id: 5, application: {}
        expect(response).to redirect_to(application_path(valid_app.id))
      end

      it "should re-render to new when invalid" do
        expect(Application).to receive(:find).and_return(invalid_app)
        post :update, id: 5, application: {}
        expect(response).to render_template("naf/applications/edit")
      end
    end

    # Ensure that some instance variables are set
    after(:each) do
      cols = assigns(:cols)
      attributes = assigns(:attributes)
    end

  end
end
