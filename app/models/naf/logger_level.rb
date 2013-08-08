module Naf
  class LoggerLevel < NafBase
    # Protect from mass-assignment issue
    attr_accessible :level

    #---------------------
    # *** Associations ***
    #+++++++++++++++++++++

    has_many :logger_style_names,
      class_name: '::Naf::LoggerStyleName'

    #--------------------
    # *** Validations ***
    #++++++++++++++++++++

    validates :level, uniqueness: true,
                      presence: true

  end
end
