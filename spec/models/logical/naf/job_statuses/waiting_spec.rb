require 'spec_helper'

module Logical
  module Naf
    module JobStatuses

      describe Waiting do

        context "no conditions" do
          
          let!(:conditions) { "" }

          it "returns executable query" do
            expect { ActiveRecord::Base.connection.execute(Waiting.all(conditions)) }.to_not raise_error
          end

        end

        context "with conditions" do

          let!(:conditions) { "TEST STRING" }

          it "adds conditions to returned sql string" do
            expect(Waiting.all(conditions).include?(conditions)).to be_true
          end

        end

      end

    end
  end
end
