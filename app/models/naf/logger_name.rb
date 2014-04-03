module Naf
  class LoggerName < NafBase
    # Protect from mass-assignment issue
    attr_accessible :name

    #---------------------
    # *** Associations ***
    #+++++++++++++++++++++

    has_many :logger_style_names,
      class_name: '::Naf::LoggerStyleName'
    has_many :logger_styles,
      through: :logger_style_names

    #--------------------
    # *** Validations ***
    #++++++++++++++++++++

    validates :name, uniqueness: true,
                     presence: true

  end
end
