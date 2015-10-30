require 'spec_helper'

module Naf

  describe LogParsersController do

    before do
      allow_any_instance_of(Logical::Naf::LogParser::JobDownloader).to receive(:logs_for_download).and_return("Test Log String")
    end

    it "raises no exceptions" do
      expect { get :download, {'record_id' => 3} }.not_to raise_error
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
      expect(disposition.include?("attachment")).to be_truthy
    end

  end

end
