module Naf
  class LoggerStyle < NafBase
    # Protect from mass-assignment issue
    attr_accessible :name,
                    :note,
                    :logger_style_names_attributes

    #---------------------
    # *** Associations ***
    #+++++++++++++++++++++

    has_many :logger_style_names,
      class_name: '::Naf::LoggerStyleName'
    has_many :logger_names,
      through: :logger_style_names

    accepts_nested_attributes_for :logger_style_names

    #--------------------
    # *** Validations ***
    #++++++++++++++++++++

    validates :name, uniqueness: true,
                     presence: true
    validate :check_logger_style_names_attributes

    before_save :check_blank_values

    #-------------------------
    # *** Instance Methods ***
    #+++++++++++++++++++++++++

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

    private

    def check_blank_values
      self.note = nil if self.note.blank?
    end

  end
end
