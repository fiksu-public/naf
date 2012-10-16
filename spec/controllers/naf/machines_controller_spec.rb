require 'spec_helper'

module Naf
  describe MachinesController do

    
    it "should respond with the index action" do
      Machine.should_not_receive(:all).and_return([])
      get :index
      response.should render_template("naf/machines/index")
      response.should be_success
    end

    it "should respond with the show action" do
      id = 5
      Machine.should_receive(:find).with("5").and_return(nil)
      get :show, :id => id
      response.should render_template("naf/record")
      response.should be_success
    end

    it "should respond with the edit action" do
      id = 5
      Machine.should_receive(:find).with("5").and_return(nil)
      get :edit, :id => id
      response.should render_template("naf/machines/edit")
      response.should be_success
    end

    it "should respond with affinity new" do
      Machine.should_receive(:new).and_return(nil)
      get :new
      response.should render_template("naf/machines/new")
      response.should be_success
    end


    it "should delete the record and redirect ot index actions" do
      machine = mock_model(Machine, :id => 5)
      Machine.should_receive(:find).with("5").and_return(machine)
      machine.should_receive(:destroy).and_return(true)
      delete :destroy, :id => 5
      response.should redirect_to machines_path
    end
    
    context "on the create action" do
      let(:valid_machine)    { mock_model(Machine, :save => true, :id => 5)  }
      let(:invalid_machine) { mock_model(Machine, :save => false) }

      it "should redirect to show when valid" do
        Machine.should_receive(:new).and_return(valid_machine)
        post :create, :machine =>{}
        response.should redirect_to(machine_path(valid_machine.id))
      end
      it "should re-render to new when invalid" do
        Machine.should_receive(:new).and_return(invalid_machine)
        post :create, :machine => {}
        response.should render_template("naf/machines/new")
      end
    end

    context "on the updated action" do
      let(:valid_machine)   { mock_model(Machine, :update_attributes => true, :id => 5) }
      let(:invalid_machine) { mock_model(Machine, :update_attributes => false,:id => 5) }
     
      it "should redirect to show when valid" do
        Machine.should_receive(:find).with("5").and_return(valid_machine)
        post :update, :id => 5, :machine =>{}
        response.should redirect_to(machine_path(valid_machine.id))
      end
      it "should re-render to new when invalid" do
        Machine.should_receive(:find).and_return(invalid_machine)
        post :update, :id => 5, :machine => {}
        response.should render_template("naf/machines/edit")
      end
    end


    # Ensure that some instance variables are set
    after(:each) do
      cols = assigns(:cols)
      attributes = assigns(:attributes)
    end
  
  end
end
