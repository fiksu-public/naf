require 'spec_helper'

module Logical
  module Naf
    module JobStatuses

      describe FinishedLessMinute do

        context "no conditions" do
          
          let!(:conditions) { "" }

          it "returns executable query" do
            expect { ActiveRecord::Base.connection.execute(FinishedLessMinute.all(conditions)) }.to_not raise_error
          end

        end

        context "with conditions" do

          let!(:conditions) { "TEST STRING" }

          it "adds conditions to returned sql string" do
            expect(FinishedLessMinute.all(conditions).include?(conditions)).to be_truthy
          end

        end

      end

    end
  end
end
