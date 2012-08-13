module NafGeneratorHelper
  def self.included(base)
    base.extend(ClassMethods)
  end
  module ClassMethods
    def to_lowercase_underscored_format(str)
      output, temp = [], ""
      str.split(/([[:upper:]][[:lower:]]*)/)
        .delete_if(&:empty?)
        .map(&:downcase).each do |i|
        if i.length > 1
          if temp.length > 0
            output << temp
            temp = ""
          end
          output << i
        else
          temp << i
        end
      end
      output << temp if temp.length > 0
      output.join('_')
    end

    def default_postgres_schema
      if Naf.const_defined?("JOB_SYSTEM_SCHEMA_NAME")
        Naf::JOB_SYSTEM_SCHEMA_NAME
      else
        to_lowercase_underscored_format(Rails.application.class.parent_name) + "_job_system"
      end
    end

  end
end
