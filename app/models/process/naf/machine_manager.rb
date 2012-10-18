module Process::Naf
  class MachineManager < ::Process::Naf::Application
    opt :server_name, "set the machines server name (use with --create-new-machine)", :type => :string
    opt :server_note, "set the machines server note (use with --create-new-machine)", :type => :string
    opt :server_address, "set the machines server address (use with --create-new-machine)", :type => :string, :default => ::Naf::Machine.machine_ip_address
    opt :create_new_machine, "create a new machine"
    opt :enabled, "enable machine"
    opt :disabled, "disable machine", :var => :enabled, :set => :false
    opt :thread_pool_size, "how many scripts can run at once", :type => :int
    opt :add_affinity, "add an affinity", :choices => []

    def pre_work
      super
      if @create_new_machine
        machine = ::Naf::Machine.find_by_server_address(@server_address)
        if machine.present?
          puts "--create-new-machine: Machine address #{@server_address} already exists -- nothing done"
          exit 1
        end
        
        machine = ::Naf::Machine.find_or_create_by_server_address(@server_address)
        machine.server_note = @server_note unless @server_note.nil?
        machine.server_name = @server_name unless @server_name.nil?
        machine.enabled = @enabled unless @enabled.nil?
        machine.thread_pool_size = @thread_pool_size unless @thread_pool_size.nil?
        machine.save!

        puts machine
        exit 0
      end
    end

    def work
      machine = ::Naf::Machine.local_machine

      unless machine.present?
        logger.fatal "This machine is not configued correctly (ipaddress: #{::Naf::Machine.machine_ip_address})."
        logger.fatal "Please update #{::Naf::Machine.table_name} with an entry for this machine."
        logger.fatal "Exiting..."
        exit 1
      end

      logger.info machine
    end
  end
end
