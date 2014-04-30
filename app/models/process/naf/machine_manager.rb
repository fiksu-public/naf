module Process::Naf
  class MachineManager < ::Process::Naf::Application
    opt :server_name, "set the machines server name (use with --update-machine)", type: :string
    opt :server_note, "set the machines server note (use with --update-machine)", type: :string
    opt :server_address, "set the machines server address (use with --update-machine)", default: ::Naf::Machine.machine_ip_address
    opt :update_machine, "create or update an machine entry"
    opt :enabled, "enable machine"
    opt :disabled, "disable machine", var: :enabled, set: :false
    opt :thread_pool_size, "how many scripts can run at once", type: :int
    opt :list_affinities, "show all affinities"
    opt :add_affinities, "add an affinity slot", type: :strings
    opt :add_weight_affinities, "add afffinity weights for cpu and memory", default: true

    def work
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
          server_name = (`hostname`).strip
          machine = ::Naf::Machine.find_by_server_name(server_name)
          if machine.blank?
            machine = ::Naf::Machine.create(server_address: @server_address,
                                            server_name: server_name)
            add_default_affinities(machine)
          else
            machine.server_address = @server_address
            machine.save!
          end
        end

        machine.server_note = @server_note unless @server_note.nil?
        machine.server_name = @server_name unless @server_name.nil?
        machine.enabled = @enabled unless @enabled.nil?
        machine.thread_pool_size = @thread_pool_size unless @thread_pool_size.nil?
        machine.save!
      else
        machine = ::Naf::Machine.find_by_server_address(@server_address)

        unless machine.present?
          puts "Machine address #{@server_address} is not present -- use --update-machine"
          exit 1
        end
      end

      if @add_affinities
        @add_affinities.each do |affinity_string|
          #
          # Parse the argument string. It should consists of 2 or 3 words separated
          # by underscores.
          #
          # Example:
          #   - location_1_required
          #   - purpose_large
          #
          parts = affinity_string.split('_')
          if parts.length == 2
            classification_name = parts[0]
            affinity_name = parts[1]
            required = false
          elsif parts.length == 3
            classification_name = parts[0]
            affinity_name = parts[1]
            required = true
          else
            puts "no idea how to interpret affinity classification in: '#{affinity_string}'"
            exit 1
          end

          # Find the Affinity Classification in the Database
          affinity_classification = ::Naf::AffinityClassification.
            find_by_affinity_classification_name(classification_name)
          unless affinity_classification
            puts "could not find affinity classification: '#{classification_name}'"
            exit 1
          end

          # Find the Affinity in the Database
          affinity = ::Naf::Affinity.
            find_by_affinity_classification_id_and_affinity_name(affinity_classification.id,
                                                                 affinity_name)
          unless affinity
            puts "could not find affinity: '#{affinity_name}' with classification: '#{classification_name}'"
            exit 1
          end

          # Create an affinity slot for the machine
          machine.machine_affinity_slots.create(affinity_id: affinity.id,
                                                required: required)
        end
      end

      puts "Address: #{machine.server_address}"
      puts "Name: #{machine.server_name}" unless machine.server_name.nil?
      puts "Note: #{machine.server_note}" unless machine.server_note.nil?
      puts "Enabled: #{machine.enabled}"
      puts "Thread Pool Size: #{machine.thread_pool_size}"

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
    end

    private

    def add_default_affinities(machine)
      # Add Machine Affinity
      classification = ::Naf::AffinityClassification.machine.id
      affinity = ::Naf::Affinity.
        find_or_create_by_affinity_classification_id_and_affinity_name(classification, machine.id.to_s)
      machine.machine_affinity_slots.create(affinity_id: affinity.id)

      if machine == ::Naf::Machine.current
        # Add Purpose Affinity
        instance_type = `source /var/spool/ec2/meta-data.sh && echo $EC2_INSTANCE_TYPE`
        if instance_type.present?
          classification = ::Naf::AffinityClassification.purpose.id
          affinity = ::Naf::Affinity.
            find_or_create_by_affinity_classification_id_and_affinity_name(classification, instance_type)
          machine.machine_affinity_slots.create(affinity_id: affinity.id)
        end

        # Add Weight Affinity
        classification = ::Naf::AffinityClassification.weight.id
        machine_cpus = (`cat /proc/cpuinfo | grep processor | wc -l`).strip.to_i
        machine_memory = (`cat /proc/meminfo | grep MemTotal`).slice(/\d+/).to_i / (1024 * 1024)
        cpu_affinity = ::Naf::Affinity.
          find_or_create_by_affinity_classification_id_and_affinity_name(classification, 'cpus')
        memory_affinity = ::Naf::Affinity.
          find_or_create_by_affinity_classification_id_and_affinity_name(classification, 'memory')
        machine.machine_affinity_slots.create(affinity_id: cpu_affinity.id, affinity_parameter: machine_cpus)
        machine.machine_affinity_slots.create(affinity_id: memory_affinity.id, affinity_parameter: machine_memory)
      end
    end

  end
end
