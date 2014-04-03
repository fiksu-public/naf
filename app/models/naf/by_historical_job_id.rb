module Naf
  class ByHistoricalJobId < ::Partitioned::ByIntegerField
    self.abstract_class = true

    # Protect from mass-assignment issue
    attr_accessible :historical_job_id

    #---------------------
    # *** Associations ***
    #+++++++++++++++++++++

    belongs_to :historical_job,
      class_name: "::Naf::HistoricalJob"

    #--------------------
    # *** Validations ***
    #++++++++++++++++++++

    validates :historical_job_id, presence: true

    #------------------
    # *** Partition ***
    #++++++++++++++++++

    partitioned do |partition|
      partition.index :id, unique: true

      partition.foreign_key lambda { |model, *partition_key_values|
        return ::Partitioned::PartitionedBase::Configurator::Data::ForeignKey.
          new(model.partition_integer_field,
              ::Naf::HistoricalJob.partition_table_name(*partition_key_values),
              :id)
      }

      partition.janitorial_creates_needed lambda { |model, *partition_key_values|
        sequence_name = model.connection.default_sequence_name(model.table_name)
        current_id = model.find_by_sql("select last_value as id from #{sequence_name}").first.id
        start_range = [0, current_id - (model.partition_table_size * model.partition_num_lead_buffers)].max
        end_range = current_id + (model.partition_table_size * model.partition_num_lead_buffers)

        return model.partition_generate_range(start_range, end_range).reject{ |p| model.sql_adapter.partition_exists?(p) }
      }

      partition.janitorial_archives_needed []
      partition.janitorial_drops_needed lambda { |model, *partition_key_values|
        sequence_name = model.connection.default_sequence_name(model.table_name)
        current_id = model.find_by_sql("select last_value as id from #{sequence_name}").first.id
        partition_key_value = current_id - (model.partition_table_size * model.partition_num_lead_buffers)
        partition_key_values_to_drop = []
        while model.sql_adapter.partition_exists?(partition_key_value)
          partition_key_values_to_drop << partition_key_value
          partition_key_value -= model.partition_table_size
        end

        return partition_key_values_to_drop
      }
    end

    #----------------------
    # *** Class Methods ***
    #++++++++++++++++++++++

    # the field to partition on
    # @return [Integer] re-routed to {#self.partition_foreign_key}
    def self.partition_integer_field
      return :historical_job_id
    end

    def self.connection
      return ::Naf::NafBase.connection
    end

    def self.full_table_name_prefix
      return ::Naf::NafBase.full_table_name_prefix
    end

    def self.partition_table_size
      return ::Naf::HistoricalJob.partition_table_size
    end

    def self.partition_num_lead_buffers
      return ::Naf::HistoricalJob.partition_num_lead_buffers
    end

  end
end
