require 'spec_helper'

module Naf
  describe AffinitiesController do

    
    it "should respond with the affinity index" do
      Affinity.should_receive(:all).and_return([])
      get :index
      response.should render_template("naf/datatable")
      response.should be_success
    end

    it "should respond with the affinity show" do
      id = 5
      Affinity.should_receive(:find).with("5").and_return(nil)
      get :show, :id => id
      response.should render_template("naf/record")
      response.should be_success
    end

    it "should respond with affinity edit" do
      id = 5
      Affinity.should_receive(:find).with("5").and_return(nil)
      get :edit, :id => id
      response.should render_template("naf/affinities/edit")
      response.should be_success
    end

    it "should respond with affinity new" do
      Affinity.should_receive(:new).and_return(nil)
      get :new
      response.should render_template("naf/affinities/new")
      response.should be_success
    end
    
    
    context "on the create action" do
      let(:valid_affinity)   { mock_model(Affinity, :save => true, :id => 5)  }
      let(:invalid_affinity) { mock_model(Affinity, :save => false) }
        it "should redirect to show when valid" do
          Affinity.should_receive(:new).and_return(valid_affinity)
        post :create, :affinity =>{}
        response.should redirect_to(affinity_path(valid_affinity.id))
      end
      it "should re-render to new when invalid" do
        Affinity.should_receive(:new).and_return(invalid_affinity)
        post :create, :affinity => {}
        response.should render_template("naf/affinities/new")
      end
    end

    context "on the updated action" do
      let(:valid_affinity)   { mock_model(Affinity, :update_attributes => true, :id => 5) }
      let(:invalid_affinity) { mock_model(Affinity, :update_attributes => false,:id => 5) }
     
      it "should redirect to show when valid" do
        Affinity.should_receive(:find).with("5").and_return(valid_affinity)
        post :update, :id => 5, :affinity =>{}
        response.should redirect_to(affinity_path(valid_affinity.id))
      end
      it "should re-render to new when invalid" do
        Affinity.should_receive(:find).and_return(invalid_affinity)
        post :update, :id => 5, :affinity => {}
        response.should render_template("naf/affinities/edit")
      end
    end

    # Ensure that some instance variables are set
    after(:each) do
      cols = assigns(:cols)
      attributes = assigns(:attributes)
    end
  
  

    
  end
end
