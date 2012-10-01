module Naf
  class ApplicationRunGroupRestriction < NafBase
    NO_RESTRICTIONS = 1
    ONE_AT_A_TIME = 2
    ONE_PER_MACHINE = 3

    def self.no_restrictions
      return find(NO_RESTRICTIONS)
    end

    def self.one_at_a_time
      return find(ONE_AT_A_TIME)
    end

    def self.one_per_machine
      return find(ONE_PER_MACHINE)
    end
  end
end
