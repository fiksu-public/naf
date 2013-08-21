module Naf
  class MachineRunnerInvocation < NafBase
    # Protect from mass-assignment issue
    attr_accessible :machine_runner_id,
                    :pid,
                    :is_running,
                    :wind_down,
                    :commit_information,
                    :branch_name,
                    :repository_name,
                    :deployment_tag

    #---------------------
    # *** Associations ***
    #+++++++++++++++++++++

    belongs_to :machine_runner,
      class_name: '::Naf::MachineRunner'

    #--------------------
    # *** Validations ***
    #++++++++++++++++++++

    validates :machine_runner_id,
              :pid,
              :commit_information,
              :branch_name,
              :repository_name,
              :deployment_tag, presence: true

  end
end
