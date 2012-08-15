module Naf
  class ApplicationRunGroup < NafBase

    validates :application_run_group_restriction_id, :presence => true
    validates :application_run_group_name, {:presence => true, :length => {:minimum => 3}}

    has_many :application_schedules, :class_name => '::Naf::ApplicationSchedule', :dependent => :destroy

    belongs_to :application_run_group_restriction, :class_name => '::Naf::ApplicationRunGroupRestriction'

    attr_accessible :application_run_group_name, :application_run_group_restriction_id

    delegate :application_run_group_restriction_name, :to => :application_run_group_restriction
  end
end
