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
      where("#{::Naf.schema_name}.machines.enabled IS TRUE")
    end

    def self.running
      joins(:machine_runner_invocations).
      where("#{::Naf.schema_name}.machine_runner_invocations.dead_at IS NULL AND
        #{::Naf.schema_name}.machine_runner_invocations.wind_down_at IS NULL")
    end

    def self.winding_down
      joins(:machine_runner_invocations).
      where("#{::Naf.schema_name}.machine_runner_invocations.dead_at IS NULL AND
        #{::Naf.schema_name}.machine_runner_invocations.wind_down_at IS NOT NULL")
    end

    def self.dead
      (::Naf::MachineRunner.joins(:machine).where("#{::Naf.schema_name}.machines.enabled IS TRUE").pluck(:machine_id) -
        ::Naf::MachineRunner.running.pluck(:machine_id)).uniq
    end

  end
end
