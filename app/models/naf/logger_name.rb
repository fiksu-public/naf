module Naf
  class LoggerName < NafBase
    validates :name, :uniqueness => true, :presence => true

    has_many :logger_style_names, :class_name => '::Naf::LoggerStyleName'
    has_many :logger_styles, :through => :logger_style_names

    attr_accessible :name
  end
end