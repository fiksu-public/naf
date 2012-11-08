module Naf
  class LoggerLevel < NafBase
    validates :level, :uniqueness => true, :presence => true

    has_many :logger_style_names
  end
end