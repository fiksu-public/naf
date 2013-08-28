module Naf
  class MachineRunner < NafBase
    # Protect from mass-assignment issue
    attr_accessible :machine_id,
                    :runner_cwd

    #---------------------
    # *** Associations ***
    #+++++++++++++++++++++

    belongs_to :machine,
      class_name: '::Naf::Machine'
    has_many :machine_runner_invocations,
      class_name: '::Naf::MachineRunnerInvocation'

    #--------------------
    # *** Validations ***
    #++++++++++++++++++++

    validates :machine_id,
              :runner_cwd, presence: true
    validates :machine_id, uniqueness: { scope: :runner_cwd }

    #----------------------
    # *** Class Methods ***
    #++++++++++++++++++++++

    def self.enabled
      joins(:machine).
      where('naf.machines.enabled IS TRUE')
    end

    def self.running
      joins(:machine_runner_invocations).
      where('naf.machine_runner_invocations.is_running IS TRUE AND naf.machine_runner_invocations.wind_down IS FALSE')
    end

    def self.winding_down
      joins(:machine_runner_invocations).
      where('naf.machine_runner_invocations.is_running IS TRUE AND naf.machine_runner_invocations.wind_down IS TRUE')
    end

    def self.dead
      joins(:machine).
      joins(:machine_runner_invocations).
      where('naf.machines.enabled IS TRUE').
      where('naf.machine_runner_invocations.is_running IS FALSE').
      where('NOT EXISTS(
          SELECT
            1
          FROM
            naf.machine_runner_invocations AS mri
          WHERE
            mri.machine_runner_id = naf.machine_runners.id AND
            mri.is_running IS TRUE
        )
      ')
    end

  end
end
