module Process::Naf
  class MachineManager < ::Process::Naf::Application
    opt :server_name, "set the machines server name (use with --create-new-machine)", :type => :string
    opt :server_note, "set the machines server note (use with --create-new-machine)", :type => :string
    opt :server_address, "set the machines server address (use with --create-new-machine)", :type => :string, :default => ::Naf::Machine.machine_ip_address
    opt :update_machine, "create or update an machine entry"
    opt :enabled, "enable machine"
    opt :disabled, "disable machine", :var => :enabled, :set => :false
    opt :thread_pool_size, "how many scripts can run at once", :type => :int
    opt :list_affinities, "show all affinities"
    opt :add_affinity, "add an affinity slot", :choices => []
    opt :add_required_affinity, "add a required affinity slot", :choices => []

    def initialize
      super
      selectable_affinities = ::Naf::Affinity.selectable.map do |affinity|
        parts = [
                 affinity.affinity_classification_name,
                 affinity.affinity_name,
                ]
        parts.join('_').to_sym
      end
      update_opts :add_affinity, :choices => selectable_affinities
      update_opts :add_required_affinity, :choices => selectable_affinities.map{|a| (a.to_s + '_required').to_sym}
    end

    def pre_work
      super
      if @list_affinities
        puts "Affinities:"
        ::Naf::Affinity.all.each do |affinity|
          parts = [
                   affinity.affinity_classification_name,
                   affinity.affinity_name,
                  ]
          puts "  #{parts.join('_')}"
        end
        exit 0
      end

      if @update_machine
        machine = ::Naf::Machine.find_by_server_address(@server_address)
        if machine.blank?
          machine = ::Naf::Machine.create_by_server_address(@server_address)
          classification = ::Naf::AffinityClassification.location.id
          affinity = ::Naf::Affinity.
            find_or_create_by_affinity_classification_id_and_affinity_name(classification, @server_address)
          machine.machine_affinity_slots.create(:affinity_id => affinity.id)
        end
      else
        machine = ::Naf::Machine.find_by_server_address(@server_address)

        unless machine.present?
          puts "Machine address #{@server_address} is not present -- use --update-machine"
          exit 1
        end
      end
        
      machine.server_note = @server_note unless @server_note.nil?
      machine.server_name = @server_name unless @server_name.nil?
      machine.enabled = @enabled unless @enabled.nil?
      machine.thread_pool_size = @thread_pool_size unless @thread_pool_size.nil?
      machine.save!

      puts "Address: #{@machine.server_address}"
      puts "Name: #{@machine.server_name}" unless @machine.server_name.nil?
      puts "Note: #{@machine.server_note}" unless @machine.server_note.nil?
      puts "Enabled: #{@machine.enabled}"
      puts "Thread Pool Size: #{@machine.thread_pool_size}"

      if machine.affinities.empty?
        puts "No machine affinity slots"
      else
        puts "Machine Affinity Slots:"
        machine.machine_affinity_slots.each do |affinity_slot|
          affinity = affinity_slot.affinity
          parts = [
                   affinity.affinity_classification_name,
                   affinity.affinity_name,
                  ]
          parts << "required" if affinity_slot.required
          puts "  #{parts.join('_')}"
        end
      end
      exit 0
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
