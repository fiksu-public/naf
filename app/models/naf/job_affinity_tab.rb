module Naf
  class JobAffinityTab < ::Partitioned::ByIntegerField
    validates :job_id, :affinity_id, :presence => true

    validates_uniqueness_of :affinity_id, :scope => :job_id, :message => "has already been taken for this job"

    belongs_to :job, :class_name => "::Naf::Job"
    belongs_to :affinity, :class_name => "::Naf::Affinity"

    delegate :title, :script_type_name, :command, :to => :job
    delegate :affinity_name, :to => :affinity

    delegate :affinity_classification_name, :to => :affinity

    attr_accessible :job_id, :affinity_id

    # the field to partition on
    # @return [Integer] re-routed to {#self.partition_foreign_key}
    def self.partition_integer_field
      return :job_id
    end

    def self.connection
      return ::Naf::NafBase.connection
    end

    def self.full_table_name_prefix
      return ::Naf::NafBase.full_table_name_prefix
    end

    def self.partition_table_size
      return ::Naf::Job.partition_table_size
    end

    def self.partition_num_lead_buffers
      return ::Naf::Job.partition_num_lead_buffers
    end

    partitioned do |partition|
      partition.index :id, :unique => true
      partition.foreign_key lambda {|model, *partition_key_values|
        return Configurator::Data::ForeignKey.new(model.partition_integer_field,
                                                  ::Naf::Job.partition_name(*partition_key_values),
                                                  :id)
      }
      partition.foreign_key :affinity_id, full_table_name_prefix + "affinities"

      partition.janitorial_creates_needed lambda {|model, *partition_key_values|
        current_id = model.find_by_sql("select last_value as id from #{model.table_name}_id_seq").first.id
        start_range = [0, current_id - (model.partition_table_size * model.partition_num_lead_buffers)].max
        end_range = current_id + (model.partition_table_size * model.partition_num_lead_buffers)
        return model.partition_generate_range(start_range, end_range).reject{|p| model.sql_adapter.partition_exists?(p)}
      }
      partition.janitorial_archives_needed []
      partition.janitorial_drops_needed lambda {|model, *partition_key_values|
        current_id = model.find_by_sql("select last_value as id from #{model.table_name}_id_seq").first.id
        start_range = [0, current_id - (model.partition_table_size * model.partition_num_lead_buffers)].max
        end_range = current_id + (model.partition_table_size * model.partition_num_lead_buffers)
        return model.partition_generate_range(start_range, end_range).reverse.select{|p| model.sql_adapter.partition_exists?(p)}
      }
    end
  end
end
