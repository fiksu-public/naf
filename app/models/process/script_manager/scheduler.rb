module Process:ScriptManager
  class Scheduler
    def work
      thread_scheduling
      thread_listener
    end

    def schedule_updater
      read_from_db
      update_schedule
    end

    def queue_manager
    end

    def service_manager
    end
  end
end

