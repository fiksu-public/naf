require 'spec_helper'

module Logical
  module Naf
    module JobStatuses

      describe Running do

        context "no conditions" do
          
          let!(:conditions) { "" }

          it "returns executable query" do
            expect { ActiveRecord::Base.connection.execute(Running.all(conditions)) }.to_not raise_error
          end

        end

        context "with conditions" do

          let!(:conditions) { "TEST STRING" }

          it "adds conditions to returned sql string" do
            expect(Running.all(conditions).include?(conditions)).to be_true
          end

          it "accepts a status argument as well" do
            expect { Running.all(:queued, conditions) }.to_not raise_error
          end

        end

      end

    end
  end
end
