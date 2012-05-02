module Process::Naf
  class Runner < Af::DaemonProcess
    def work
      # scheduler rope
    end

    def watchdog
      # this check to see if any machines have gone down
      ## ping each machine
      ### if not accessible mark down
    end

    def scheduler
      # fetch all from schedule tables
      # find last runs for all schedules (from db)
    end
  end
end
