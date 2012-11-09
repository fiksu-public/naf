module Naf
  class LoggerStyle < NafBase
    validates :name, :uniqueness => true, :presence => true
    validate :check_logger_style_names_attributes

    has_many :logger_style_names, :class_name => '::Naf::LoggerStyleName'
    has_many :logger_names, :through => :logger_style_names

    attr_accessible :name, :note, :logger_style_names_attributes

    accepts_nested_attributes_for :logger_style_names

    def _logger_names
      logger_style_names.map do |lsn|
        lsn.logger_name.name
      end.join(', ')
    end

    def logger_levels
      logger_style_names.map do |lsn|
        lsn.logger_level.level
      end.join(', ')
    end

    def check_logger_style_names_attributes
      if logger_style_names.map{ |ln| ln.logger_name_id }.uniq!
        errors.add(:logger_name_id, "should be an uniqueness")
      end
    end

  end
end