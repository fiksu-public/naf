require 'spec_helper'

module Naf
  describe ApplicationScheduleAffinityTabsController do

    let(:model_class) { ApplicationScheduleAffinityTab }

    it "should respond with index action nested under application schedule" do
      expect(model_class).to receive(:where).with({ application_schedule_id: '1' }).and_return([])
      get :index, application_schedule_id: 1
      expect(response).to render_template('naf/datatable')
      expect(response).to be_success
    end

    it "should respond with the show action" do
      expect(model_class).to receive(:find).with('5').and_return(nil)
      schedule = double('schedule')
      expect(schedule).to receive(:application).and_return(nil)
      expect(ApplicationSchedule).to receive(:find).with('1').and_return(schedule)
      get :show, id: 5, application_schedule_id: 1
      expect(response).to render_template('naf/record')
      expect(response).to be_success
    end

    it "should respond with the edit action" do
      expect(model_class).to receive(:find).with('5').and_return(nil)
      schedule = double('schedule')
      expect(schedule).to receive(:application).and_return(nil)
      expect(ApplicationSchedule).to receive(:find).with('1').and_return(schedule)
      get :edit, id: 5, application_schedule_id: 1
      expect(response).to render_template('naf/application_schedule_affinity_tabs/edit')
      expect(response).to be_success
    end

    it "should respond with the new action" do
      expect(model_class).to receive(:new).and_return(nil)
      schedule = double('schedule')
      expect(schedule).to receive(:application).and_return(nil)
      expect(ApplicationSchedule).to receive(:find).with('1').and_return(schedule)
      get :new, id: 5, application_schedule_id: 1
      expect(response).to render_template('naf/application_schedule_affinity_tabs/new')
      expect(response).to be_success
    end

    context "on the create action" do
      let(:valid_tab)   { mock_model(model_class, save: true,
                                                  id: 5,
                                                  application_schedule_id: 1,
                                                  application_id: 1) }
      let(:invalid_tab) { mock_model(model_class, save: false) }
      let(:schedule)    { mock_model(ApplicationSchedule, id: 1) }
      let(:application) { mock_model(Application, id: 1)  }

      subject do
          post :create, application_schedule_id: 1, application_id: 1
      end

      before do
        expect(ApplicationSchedule).to receive(:find).with('1').and_return(schedule)
      end

      it "should redirect to show when valid" do
        expect(model_class).to receive(:new).and_return(valid_tab)
        allow(valid_tab).to receive(:affinity_name).and_return('Test Name')
        path = application_schedule_application_schedule_affinity_tab_path(schedule, valid_tab)
        expect(subject).to redirect_to(path)
      end
      it "should re-render to new when invalid" do
        expect(model_class).to receive(:new).and_return(invalid_tab)
        expect(subject).to render_template('naf/application_schedule_affinity_tabs/new')
      end
    end

    context "on the update action" do
      let(:valid_tab)   { mock_model(model_class, update_attributes: true,
                                                  id: 5,
                                                  application_schedule_id: 1,
                                                  application_id: 1)  }
      let(:invalid_tab) { mock_model(model_class, update_attributes: false,
                                                  id: 5,
                                                  application_schedule_id: 1,
                                                  application_id: 1) }
      let(:schedule)    { mock_model(ApplicationSchedule, id: 1) }

      subject do
        put :update, application_schedule_id: 1, id: 5
      end

      before do
        expect(ApplicationSchedule).to receive(:find).with('1').and_return(schedule)
      end

      it "should redirect to show when valid" do
        expect(model_class).to receive(:find).and_return(valid_tab)
        allow(valid_tab).to receive(:affinity_name).and_return('Test Name')
        path = application_schedule_application_schedule_affinity_tab_path(schedule, valid_tab)
        expect(subject).to redirect_to(path)
      end

      it "should re-render to edit  when invalid" do
        expect(model_class).to receive(:find).and_return(invalid_tab)
        expect(subject).to render_template('naf/application_schedule_affinity_tabs/edit')
      end
    end

    # Ensure that some instance variables are set
    after(:each) do
      cols = assigns(:cols)
      attributes = assigns(:attributes)
    end

  end
end
