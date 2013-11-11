require 'yajl'

module Logical::Naf
  module LogParser
    class Base

      REGEX_OPTIONS = {
        'i' => Regexp::IGNORECASE,
        'x' => Regexp::EXTENDED,
        'm' => Regexp::MULTILINE
      }
      DATE_REGEX = /((\d){8}_(\d){6})/
      UUID_REGEX = /[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}/
      LOG_SIZE_CHUNKS = 50

      attr_accessor  :search_params,
                     :regex_options,
                     :grep,
                     :search_from_time,
                     :search_to_time

      def initialize(params)
        @search_params = params['search_params'].nil? ? '' : params['search_params']
        @regex_options = get_option_value(params['regex_options'])
        @grep = params['grep']
        @search_from_time = params['from_time']
        @search_to_time = params['to_time']
      end

      def log_within_time_range(log_time)
        return true if (search_from_time.join('').blank? && search_to_time.join('').blank?) || log_time.blank?

        if search_from_time.join('').present? && search_to_time.join('').present?
          Time.parse(log_time) <= Time.parse(build_time_string(search_to_time)) &&
          Time.parse(log_time) >= Time.parse(build_time_string(search_from_time))
        elsif search_from_time.join('').present?
          Time.parse(log_time) >= Time.parse(build_time_string(search_from_time))
        elsif search_to_time.join('').present?
          Time.parse(log_time) <= Time.parse(build_time_string(search_to_time))
        end
      end

      def build_time_string(search_time)
        # Year
        search_built_time = search_time[0] + "-"
        # Month
        if search_time[1].to_i < 10
          search_built_time << '0' + search_time[1] + '-'
        else
          search_built_time << search_time[1] + '-'
        end
        # Day
        if search_time[2].to_i < 10
          search_built_time << '0' + search_time[2] + ' '
        else
          search_built_time << search_time[2] + ' '
        end
        # Hour
        search_built_time << search_time[3] + ':'
        # Minute
        if search_time[4].to_i < 10
          search_built_time << '0' + search_time[4]
        else
          search_built_time << search_time[4]
        end
        # Second
        search_built_time << ':00 UTC'

        search_built_time
      end

      def check_new_logs(line_number)
        return true if log_type == 'old'

        if newest_line_checked.present?
          line_number.to_i > newest_line_checked
        else
          false
        end
      end

      def get_option_value(options)
        return 0 if options.blank?

        options = options.split(//)
        result = 0
        options.each do |opt|
          result |= REGEX_OPTIONS[opt]
        end

        result
      end

    end
  end
end
