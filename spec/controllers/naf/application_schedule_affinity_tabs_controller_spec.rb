require 'spec_helper'

module Naf
  describe ApplicationScheduleAffinityTabsController do

    let(:model_class) { ApplicationScheduleAffinityTab }

    it "should respond with index action nested under application schedule" do
      model_class.should_receive(:where).with({ application_schedule_id: "1" }).and_return([])
      get :index, application_schedule_id: 1
      response.should render_template("naf/datatable")
      response.should be_success
    end

    it "should respond with the show action" do
      model_class.should_receive(:find).with("5").and_return(nil)
      schedule = double('schedule')
      schedule.should_receive(:application).and_return(nil)
      ApplicationSchedule.should_receive(:find).with("1").and_return(schedule)
      get :show, id: 5, application_schedule_id: 1
      response.should render_template("naf/record")
      response.should be_success
    end

    it "should respond with the edit action" do
      model_class.should_receive(:find).with("5").and_return(nil)
      schedule = double('schedule')
      schedule.should_receive(:application).and_return(nil)
      ApplicationSchedule.should_receive(:find).with("1").and_return(schedule)
      get :edit, id: 5, application_schedule_id: 1
      response.should render_template("naf/application_schedule_affinity_tabs/edit")
      response.should be_success
    end

    it "should respond with the new action" do
      model_class.should_receive(:new).and_return(nil)
      schedule = double('schedule')
      schedule.should_receive(:application).and_return(nil)
      ApplicationSchedule.should_receive(:find).with("1").and_return(schedule)
      get :new, id: 5, application_schedule_id: 1
      response.should render_template("naf/application_schedule_affinity_tabs/new")
      response.should be_success
    end

    context "on the create action" do
      let(:valid_tab)   { mock_model(model_class, save: true, id: 5, application_schedule_id: 1, application_id: 1) }
      let(:invalid_tab) { mock_model(model_class, save: false) }
      let(:schedule)    { mock_model(ApplicationSchedule, id: 1) }
      let(:application) { mock_model(Application, id: 1)  }

      subject do
          post :create, application_schedule_id: 1, application_id: 1
      end

      before(:each) do
        Application.should_receive(:find).with("1").and_return(application)
        ApplicationSchedule.should_receive(:find).with("1").and_return(schedule)
      end

      it "should redirect to show when valid" do
        model_class.should_receive(:new).and_return(valid_tab)
        valid_tab.stub(:affinity_name).and_return("Test Name")
        path = application_application_schedule_application_schedule_affinity_tab_path(application, schedule, valid_tab)
        subject.should redirect_to(path)
      end
      it "should re-render to new when invalid" do
        model_class.should_receive(:new).and_return(invalid_tab)
        subject.should render_template("naf/application_schedule_affinity_tabs/new")
      end
    end

    context "on the update action" do
      let(:valid_tab)   { mock_model(model_class, update_attributes: true, id: 5, application_schedule_id: 1, application_id: 1)  }
      let(:invalid_tab) { mock_model(model_class, update_attributes: false, id: 5, application_schedule_id: 1, application_id: 1) }
      let(:schedule)    { mock_model(ApplicationSchedule, id: 1) }
      let(:application) { mock_model(Application, id: 1)  }

      subject do
          put :update, application_schedule_id: 1, application_id: 1, id: 5
      end

      before(:each) do
        Application.should_receive(:find).with("1").and_return(application)
        ApplicationSchedule.should_receive(:find).with("1").and_return(schedule)
      end

      it "should redirect to show when valid" do
        model_class.should_receive(:find).and_return(valid_tab)
        valid_tab.stub(:affinity_name).and_return("Test Name")
        path = application_application_schedule_application_schedule_affinity_tab_path(application, schedule, valid_tab)
        subject.should redirect_to(path)
      end
      it "should re-render to edit  when invalid" do
        model_class.should_receive(:find).and_return(invalid_tab)
        subject.should render_template("naf/application_schedule_affinity_tabs/edit")
      end
    end

    # Ensure that some instance variables are set
    after(:each) do
      cols = assigns(:cols)
      attributes = assigns(:attributes)
    end

  end
end
