module Naf
  class QueuedJob < NafBase
    # XXX attr_accessibles
    belongs_to :historical_job, :class_name => "::Naf::HistoricalJob", :foreign_key => :id
    belongs_to :application, :class_name => "::Naf::Application"
    belongs_to :application_type, :class_name => '::Naf::ApplicationType'
    belongs_to :application_run_group_restriction, :class_name => "::Naf::ApplicationRunGroupRestriction"

    def self.order_by_priority
      return order("priority,created_at")
    end
  end
end
