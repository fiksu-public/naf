module Naf
  class ApplicationType < NafBase
    # Protect from mass-assignment issue
    attr_accessible :enabled,
                    :script_type_name,
                    :description,
                    :invocation_method

    SCRIPT_RUNNER = "#{Gem.ruby} #{Rails.root}/script/rails runner"

    #---------------------
    # *** Associations ***
    #+++++++++++++++++++++

    has_many :applications,
      class_name: "::Naf::Application"
    has_many :historical_jobs,
      class_name: "::Naf::HistoricalJob"

    #--------------------
    # *** Validations ***
    #++++++++++++++++++++

    validates :script_type_name,
              :invocation_method, presence: true

    #-------------------------
    # *** Instance Methods ***
    #+++++++++++++++++++++++++

    def spawn(job)
      self.send(invocation_method.to_sym, job)
    end

    def invoke(job, command)
      Process.spawn({ "NAF_JOB_ID" => job.id.to_s }, command)
    end

    def rails_invocator(job)
      invoke(job, SCRIPT_RUNNER + " " + job.command)
    end

    def bash_command_invocator(job)
      invoke(job, job.command)
    end

    def bash_script_invocator(job)
      invoke(job, job.command)
    end

    def ruby_script_invocator(job)
      invoke(job, job.command)
    end

  end
end
