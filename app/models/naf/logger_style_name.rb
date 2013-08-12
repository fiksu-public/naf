module Naf
  class LoggerStyleName < NafBase
    # Protect from mass-assignment issue
    attr_accessible :logger_style_id,
                    :logger_name_id,
                    :logger_level_id

    #---------------------
    # *** Associations ***
    #+++++++++++++++++++++

    belongs_to :logger_name,
      class_name: '::Naf::LoggerName'
    belongs_to :logger_style,
      class_name: '::Naf::LoggerStyle'
    belongs_to :logger_level,
      class_name: '::Naf::LoggerLevel'

    #--------------------
    # *** Validations ***
    #++++++++++++++++++++

    validates :logger_name_id,
              :logger_level_id,
              :logger_style_id, presence: true
    validates :logger_style_id, uniqueness: { scope: :logger_name_id }

  end
end
