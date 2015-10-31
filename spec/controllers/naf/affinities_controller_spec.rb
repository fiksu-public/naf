require 'spec_helper'

module Naf
  describe AffinitiesController do


    it "should respond with the affinity index" do
      get :index
      expect(response).to be_success
    end

    it "should respond with the affinity show" do
      id = 5
      expect(Affinity).to receive(:find).with("5").and_return(nil)
      get :show, id: id
      expect(response).to be_success
    end

    it "should respond with affinity edit" do
      id = 5
      expect(Affinity).to receive(:find).with("5").and_return(nil)
      get :edit, id: id
      expect(response).to render_template("naf/affinities/edit")
      expect(response).to be_success
    end

    it "should respond with affinity new" do
      expect(Affinity).to receive(:new).and_return(nil)
      get :new
      expect(response).to render_template("naf/affinities/new")
      expect(response).to be_success
    end


    context "on the create action" do
      let(:valid_affinity) { mock_model(Affinity, save: true, id: 5, validate_affinity_name: nil) }
      let(:invalid_affinity) { mock_model(Affinity, save: false, validate_affinity_name: nil) }

      it "should redirect to show when valid" do
        expect(Affinity).to receive(:new).and_return(valid_affinity)
        post :create, affinity: {}
        expect(response).to redirect_to(affinity_path(valid_affinity.id))
      end

      it "should re-render to new when invalid" do
        expect(Affinity).to receive(:new).and_return(invalid_affinity)
        post :create, affinity: {}
        expect(response).to render_template("naf/affinities/new")
      end
    end

    context "on the updated action" do
      let(:valid_affinity)   { mock_model(Affinity, update_attributes: true, id: 5) }
      let(:invalid_affinity) { mock_model(Affinity, update_attributes: false, id: 5) }

      it "should redirect to show when valid" do
        expect(Affinity).to receive(:find).with("5").and_return(valid_affinity)
        post :update, id: 5, affinity: {}
        expect(response).to redirect_to(affinity_path(valid_affinity.id))
      end
      it "should re-render to new when invalid" do
        expect(Affinity).to receive(:find).and_return(invalid_affinity)
        post :update, id: 5, affinity: {}
        expect(response).to render_template("naf/affinities/edit")
      end
    end

    # Ensure that some instance variables are set
    after(:each) do
      cols = assigns(:cols)
      attributes = assigns(:attributes)
    end




  end
end
