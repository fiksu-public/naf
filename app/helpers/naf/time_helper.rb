module Naf
  module TimeHelper

    def time_difference(value, started_at = nil)
      seconds = value % 60
      value = (value - seconds) / 60
      minutes = value % 60
      value = (value - minutes) / 60
      hours = value % 24
      value = (value - hours) / 24
      days = value % 7
      more_hours = hours + days * 24 if days > 0

      if started_at.present?
        "-#{hours.to_i + more_hours.to_i}h#{minutes.to_i}m, #{started_at.localtime.strftime("%Y-%m-%d %r")}"
      else
        if days < 2
          "-#{hours.to_i + more_hours.to_i}h#{minutes.to_i}m#{seconds.to_i}s"
        else
          "-#{days.to_i}d#{hours.to_i}h#{minutes.to_i}m#{seconds.to_i}s"
        end
      end
    end

    def time_format(time)
      return '' if time.nil?

      value = Time.zone.now - time
      if value < 60
        return "#{value.to_i} seconds ago"
      else
        return time_difference(value)
      end
    end

  end
end
