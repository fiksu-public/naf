module Naf
  class MachineRunnerInvocation < NafBase
    # Protect from mass-assignment issue
    attr_accessible :machine_runner_id,
                    :pid,
                    :is_running,
                    :wind_down

    #---------------------
    # *** Associations ***
    #+++++++++++++++++++++

    belongs_to :machine_runner,
      class_name: '::Naf::MachineRunner'

    #--------------------
    # *** Validations ***
    #++++++++++++++++++++

    validates :machine_runner_id,
              :pid, presence: true

  end
end
