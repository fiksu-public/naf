module Naf
  class ByJobCreatedAt < ::Partitioned::ByCreatedAt
    self.abstract_class = true

    def self.partition_time_field
      return :job_created_at
    end

    def self.connection
      return ::Naf::NafBase.connection
    end

    def self.full_table_name_prefix
      return ::Naf::NafBase.full_table_name_prefix
    end

    partitioned do |partition|
      partition.janitorial_creates_needed lambda {|model, *partition_key_values|
        return model.partition_generate_range(Time.zone.now.to_date - 1.month, Time.zone.now.to_date + 1.month).reject{|p| model.sql_adapter.partition_exists?(p)}
      }
      partition.janitorial_archives_needed []
      partition.janitorial_drops_needed lambda {|model, *partition_key_values|
        partition_key_value = Time.zone.now.to_date - 1.month
        partition_key_values_to_drop = []
        while model.sql_adapter.partition_exists?(partition_key_value)
          partition_key_values_to_drop << partition_key_value
          partition_key_value -= model.partition_table_size
        end
        return partition_key_values_to_drop
      }
    end
  end
end
