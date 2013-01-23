module Naf
  class RunningJob < NafBase
    belongs_to :historical_job, :class_name => "::Naf::HistoricalJob", :foreign_key => :id
    belongs_to :application, :class_name => "::Naf::Application"
    belongs_to :application_type, :class_name => '::Naf::ApplicationType'
    belongs_to :application_run_group_restriction, :class_name => "::Naf::ApplicationRunGroupRestriction"
    belongs_to :started_on_machine, :class_name => '::Naf::Machine'
    belongs_to :marked_dead_by_machine, :class_name => '::Naf::Machine'
  end
end
