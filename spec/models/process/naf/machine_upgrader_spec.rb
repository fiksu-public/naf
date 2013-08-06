require 'spec_helper'

module Process::Naf
	describe MachineUpgrader do
		include ScriptSpecHelper

		let!(:script) { ::Process::Naf::MachineUpgrader }

    before do
      ::Naf::Application.delete_all
      ::Naf::Affinity.delete_all
    end

    after(:all) do
      system "rm naf_tables_information.csv"
    end

		describe "save information" do
      let!(:application) {
        FactoryGirl.create(:application,
          command: "puts 'hi'",
          title: 'application1')
      }
			before do
				run_script('--upgrade-option', 'save')
			end

			it "write to csv file" do
        saved_results = nil
        CSV.open('naf_tables_information.csv', 'r') do |csv|
          saved_results = csv.read
        end

        saved_results[0..10].should == [
          ['naf.applications'],
          ['id', application.id.to_s],
          ['deleted', application.deleted.to_s],
          ['application_type_id', application.application_type_id.to_s],
          ['command', "puts 'hi'"],
          ['title', 'application1'],
          ['short_name', application.short_name],
          ['log_level', application.log_level],
          ['---'],
          ['naf.applications_id_seq', ::Naf::Application.
            find_by_sql("SELECT last_value FROM naf.applications_id_seq").first['last_value']],
          ['===']
        ]
			end
		end

    describe "restore information" do
      before do
        run_script('--upgrade-option', 'restore')
      end

      it "insert records correctly" do
        ::Naf::Application.last.command.should == "puts 'hi'"
      end

      it "update table sequence correctly" do
        ::Naf::Application.find_by_sql("SELECT last_value FROM naf.applications_id_seq").
          first['last_value'].should == ::Naf::Application.last.id.to_s
      end
    end

	end
end
