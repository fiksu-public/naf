require 'spec_helper'

module Naf

  describe LogParsersController do

    before do
      Logical::Naf::LogParser::JobDownloader.any_instance.stub(:logs_for_download).and_return("Test Log String")
    end

    it "raises no exceptions" do
      assert_nothing_raised do
        get :download, {'record_id' => 3}
      end
    end

    it "has a successful response" do
      get :download, {'record_id' => 3}
      assert_response(:success)
    end

    it "returns the correct string" do
      get :download, {'record_id' => 3}
      expect(response.body).to eql("Test Log String\n")
    end

    it "has the right disposition of attachment" do
      get :download, {'record_id' => 3}
      disposition = response.header["Content-Disposition"]
      expect(disposition.include?("attachment")).to be_true
    end

  end

end
