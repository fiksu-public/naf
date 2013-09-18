require 'spec_helper'

module Naf
  describe NafBase do
    describe "with regard to configuration" do
      it "should inherit from the correct model_class" do
        NafBase.superclass.should == Naf.model_class
      end
      it "should have the correctly set full table name prefix" do
        NafBase.full_table_name_prefix.should == "#{::Naf.schema_name}."
      end
    end
  end
end
