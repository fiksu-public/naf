require 'spec_helper'

module Naf
  describe MachineAffinitySlotsController do

    let(:model_class) { MachineAffinitySlot}

    it "should respond with index action nested under machine" do
      get :index, machine_id: 1
      expect(response).to render_template("naf/datatable")
      expect(response).to be_success
    end

    it "should respond with the show action" do
      expect(Machine).to receive(:find).with("1").and_return(nil)
      expect(model_class).to receive(:find).with("5").and_return(nil)
      get :show, id: 5, machine_id: 1
      expect(response).to render_template("naf/record")
      expect(response).to be_success
    end

    it "should respond with the destroy action and redirect to nested index" do
      slot = mock_model(model_class, machine_id: 1, id: 5)
      machine = mock_model(Machine, id: 1)
      expect(Machine).to receive(:find).with("1").and_return(machine)
      expect(model_class).to receive(:find).with("5").and_return(slot)
      allow(slot).to receive(:affinity_name).and_return("Test Name")
      delete :destroy, id: 5, machine_id: 1
      index_path = machine_machine_affinity_slots_path(machine)
      expect(response).to redirect_to(index_path)
    end

    it "should respond with the edit action" do
      expect(Machine).to receive(:find).with("1").and_return(nil)
      expect(model_class).to receive(:find).with("5").and_return(nil)
      get :edit, id: 5, machine_id: 1
      expect(response).to render_template("naf/machine_affinity_slots/edit")
      expect(response).to be_success
    end

    it "should respond with the new action" do
      expect(Machine).to receive(:find).with("1").and_return(nil)
      expect(model_class).to receive(:new).and_return(nil)
      get :new, machine_id: 1
      expect(response).to render_template("naf/machine_affinity_slots/new")
      expect(response).to be_success
    end

    context "on the create action" do
      let(:valid_slot) { mock_model(model_class, save: true, id: 5, machine_id: 1)}
      let(:invalid_slot) { mock_model(model_class, save: false) }
      let(:machine) { mock_model(Machine, id: 1)  }

      subject do
        post :create, machine_affinity_slot: { machine_id: 1 }, machine_id: 1
      end

      before(:each) do
        expect(Machine).to receive(:find).with("1").and_return(machine)
      end

      it "should redirect to show when valid" do
        expect(model_class).to receive(:new).and_return(valid_slot)
        allow(valid_slot).to receive(:affinity_name).and_return("Test Name")
        path = machine_machine_affinity_slot_path(machine, valid_slot)
        expect(subject).to redirect_to(path)
      end
      it "should re-render to new when invalid" do
        expect(model_class).to receive(:new).and_return(invalid_slot)
        expect(subject).to render_template("naf/machine_affinity_slots/new")
      end
    end

    context "on the update action" do
      let(:valid_slot) { mock_model(model_class, update_attributes: true, id: 5, machine_id: 1)  }
      let(:invalid_slot) { mock_model(model_class, update_attributes: false, id: 5, machine_id: 1) }
      let(:machine) { mock_model(Machine, id: 1) }

      subject do
        put :update, machine_affinity_slot: { machine_id: 1 }, id: 5, machine_id: 1
      end

      before(:each) do
        expect(Machine).to receive(:find).with(1).and_return(machine)
      end

      it "should redirect to show when valid" do
        expect(model_class).to receive(:find).and_return(valid_slot)
        allow(valid_slot).to receive(:affinity_name).and_return("Test Name")
        path = machine_machine_affinity_slot_path(machine, valid_slot)
        expect(subject).to redirect_to(path)
      end

      it "should re-render to edit  when invalid" do
        expect(model_class).to receive(:find).and_return(invalid_slot)
        expect(subject).to render_template("naf/machine_affinity_slots/edit")
      end

    end

    # Ensure that some instance variables are set
    after(:each) do
      cols = assigns(:cols)
      attributes = assigns(:attributes)
    end

  end
end
