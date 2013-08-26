module Naf
  class MachineRunner < NafBase
    # Protect from mass-assignment issue
    attr_accessible :machine_id, :runner_cwd

    #---------------------
    # *** Associations ***
    #+++++++++++++++++++++

    belongs_to :machine, class_name: '::Naf::Machine'
    has_many :machine_runner_invocations, class_name: '::Naf::MachineRunnerInvocation'
    has_many :historical_jobs, class_name: '::Naf::HistoricalJob'

    #--------------------
    # *** Validations ***
    #++++++++++++++++++++

    validates :machine_id, :runner_cwd, presence: true
    validates :machine_id, uniqueness: { scope: :runner_cwd }

    def self.enabled
      return joins(:machine).where("machines.enabled = true")
    end
  end
end
