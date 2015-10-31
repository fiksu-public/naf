require 'spec_helper'

module Naf
  describe NafBase do
    describe "with regard to configuration" do
      it "should inherit from the correct model_class" do
        expect(NafBase.superclass).to eq(Naf.model_class)
      end
      it "should have the correctly set full table name prefix" do
        expect(NafBase.full_table_name_prefix).to eq("#{::Naf.schema_name}.")
      end
    end
  end
end
