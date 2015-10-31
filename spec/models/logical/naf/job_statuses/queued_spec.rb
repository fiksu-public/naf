require 'spec_helper'

module Logical
  module Naf
    module JobStatuses

      describe Queued do

        context "no conditions" do

          let!(:conditions) { "" }

          it "returns executable query" do
            expect { ActiveRecord::Base.connection.execute(Queued.all(conditions)) }.to_not raise_error
          end

        end

        context "custom conditions" do

          let!(:conditions) { "TEST STRING" }

          it "adds conditions to returned query" do
            sql = Queued.all(conditions)
            expect(sql.include?(conditions)).to be_truthy
          end

        end

      end

    end
  end
end
