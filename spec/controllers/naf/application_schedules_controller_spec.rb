require 'spec_helper'

module Naf
  describe ApplicationSchedulesController do
    
    let(:model_class) { ApplicationSchedule}
    
    it "should respond with index action nested under application schedule" do
      model_class.should_receive(:where).with({:application_id => "1"}).and_return([])
      get :index, :application_id => 1
      response.should render_template("naf/datatable")
      response.should be_success
    end

    it "should respond with the show action" do
      model_class.should_receive(:find).with("5").and_return(nil)
      get :show, :id => 5, :application_id => 1
      response.should render_template("naf/record")
      response.should be_success
    end
    
    it "should respond with the edit action" do
      Application.should_receive(:find).with("1").and_return(nil)
      model_class.should_receive(:find).with("5").and_return(nil)
      get :edit, :id => 5, :application_id => 1
      response.should render_template("naf/application_schedules/edit")
      response.should be_success
    end
    
    

    it "should respond with the new action" do
      Application.should_receive(:find).with("1").and_return(nil)
      model_class.should_receive(:new).and_return(nil)
      get :new, :id => 5, :application_id => 1
      response.should render_template("naf/application_schedules/new")
      response.should be_success
    end

    context "on the create action" do
      let(:valid_schedule)   { mock_model(model_class, :save => true, :id => 5,:application_id => 1)}
      let(:invalid_schedule) { mock_model(model_class, :save => false) }
      let(:application) { mock_model(Application, :id => 1)  }

      subject do 
        post :create,  :application_schedule => {}, :application_id => 1
      end

      before(:each) do
        Application.should_receive(:find).with("1").and_return(application)
      end

      it "should redirect to show when valid" do
        model_class.should_receive(:new).and_return(valid_schedule)
        path = application_application_schedule_path(application, valid_schedule)
        subject.should redirect_to(path)
      end
      it "should re-render to new when invalid" do
        model_class.should_receive(:new).and_return(invalid_schedule)
        subject.should render_template("naf/application_schedules/new")
      end
    end

    context "on the update action" do
      let(:valid_schedule)   { mock_model(model_class, :update_attributes => true, :id => 5, :application_id => 1)  }
      let(:invalid_schedule) { mock_model(model_class, :update_attributes => false, :id => 5, :application_id => 1) }
      let(:application) { mock_model(Application, :id => 1)  }

      subject do 
        put :update, :application_schedule => {}, :id => 5, :application_id => 1
      end

      before(:each) do
        Application.should_receive(:find).with("1").and_return(application)
      end
      
      it "should redirect to show when valid" do
        model_class.should_receive(:find).and_return(valid_schedule)
        path = application_application_schedule_path(application, valid_schedule)
        subject.should redirect_to(path)
      end
      it "should re-render to edit  when invalid" do
        model_class.should_receive(:find).and_return(invalid_schedule)
        subject.should render_template("naf/application_schedules/edit")
      end

    end

    context "coercing the run_start_minute" do
      let(:schedule) { mock_model(model_class, :application_id => 1, :save => true) }
      let(:application) { mock_model(Application, :id => 1)  }
      before(:each) do
        Application.should_receive(:find).with("1").and_return(application)
      end
      context "for the create action" do
        subject do
          post :create, :application_schedule => {:run_start_minute => "12:48 AM"}, :application_id =>1
        end
        it "should work" do
          model_class.should_receive(:new).with({"run_start_minute" => 48}).and_return(schedule)
          path = application_application_schedule_path(application, schedule)
          subject.should redirect_to(path)
        end       
      end
      context "for the update action" do
        subject do
          put :update, :application_schedule => {:run_start_minute => "6:48 AM"}, :application_id => 1, :id => 5
        end
        it "should work" do
          model_class.should_receive(:find).with("5").and_return(schedule)
          schedule.should_receive(:update_attributes).with({"run_start_minute" => (6*60 + 48)}).and_return(true)
          path = application_application_schedule_path(application, schedule)
          subject.should redirect_to(path)
        end
      end
    end
    
    

    # Ensure that some instance variables are set
    after(:each) do
      cols = assigns(:cols)
      attributes = assigns(:attributes)
    end
  
  

    
  end
end

