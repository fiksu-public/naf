module Naf
  class ApplicationRunGroupRestriction < NafBase
    def self.no_limit
      return @no_limit ||= find_by_application_run_group_restriction_name('no limit')
    end

    def self.limited_per_machine
      return @limited_per_machine ||= find_by_application_run_group_restriction_name('limited per machine')
    end

    def self.limited_per_all_machines
      return @limited_per_all_machines ||= find_by_application_run_group_restriction_name('limited per all machines')
    end
  end
end
