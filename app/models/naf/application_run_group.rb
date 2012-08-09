module Naf
  class ApplicationRunGroup < NafBase
    validates :application_run_group_name, {:presence => true, :length => {:minimum => 3}}

    has_many :application_schedules, :class_name => '::Naf::ApplicationSchedule', :dependent => :destroy

    attr_accessible :application_run_group_name
  end
end
