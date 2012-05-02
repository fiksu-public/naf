module Process:ScriptManager
  class Runner
    def initialize
      @is_primary_runner = false
    end

    def work
      while true
        if is_primary_runner?
          check_if_runners_are_alive
          schedule_new_things
        else
          check_if_primary_alive
        end
      end
    end

    def is_primary_runner?
      # lock table
      # is there a primary runner?
      #   yes
      #     are we it?
      #      yes - return true
      #      no - ensure we don't think we are the primary; return false
      #   no
      #     do we think we are primary?
      #       yes - ensure we are running as primary; return true
      #       no - start running as primary; return true
      # unlock table
    end

    def queue_manager
    end

    def service_manager
    end
  end
end
