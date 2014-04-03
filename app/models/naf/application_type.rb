module Naf
  class ApplicationType < NafBase
    # Protect from mass-assignment issue
    attr_accessible :enabled,
                    :script_type_name,
                    :description,
                    :invocation_method

    SCRIPT_RUNNER = "#{Gem.ruby} #{Rails.root}/script/rails runner"
    JOB_LOGGER = "#{Rails.root}/script/rails runner ::Process::Naf::Logger::JobLog.run"

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

    # This method calls Process.spawn to excute a built command. The first part
    # of the command is the execution of the job command, redirecting stderr to
    # stdout. Stdout and stderr are then sent through a pipe to be used as input
    # for the job logger. The job logger will also redirect stderr to stdout, and
    # save any crash logs. At the end of the built command, there is a exit $PIPESTATUS
    # command that will return the exit status of the whole command.
    def invoke(job, job_command)
      command = job_command + " 2>&1 | #{JOB_LOGGER} >> #{LOGGING_ROOT_DIRECTORY}/naf/crash.log 2>&1; exit $PIPESTATUS"
      Process.spawn({ 'NAF_JOB_ID' => job.id.to_s }, command)
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

    def self.rails
      @rails ||= find_by_script_type_name('rails')
    end

    def self.ruby
      @ruby ||= find_by_script_type_name('ruby')
    end

    def self.bash_command
      @bash_command ||= find_by_script_type_name('bash command')
    end

    def self.bash_script
      @bash_script ||= find_by_script_type_name('bash script')
    end

  end
end
