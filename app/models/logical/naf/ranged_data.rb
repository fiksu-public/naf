module ::Logical::Naf
  class RangedData
    def initialize(grouping_name)
      @data = {}
      @grouping_name = grouping_name
      @normalize_function, @increment_function = self.class.assign_grouping_functions(grouping_name)
    end

    def self.assign_grouping_functions(grouping_name)
      if grouping_name == "minute"
        @normalize_function = :at_beginning_of_hour
        @increment_function = :minute
      elsif grouping_name == "hour"
        @normalize_function = :at_beginning_of_hour
        @increment_function = :hour
      elsif grouping_name == "day"
        @normalize_function = :at_beginning_of_day
        @increment_function = :day
      elsif grouping_name == "week"
        @normalize_function = :at_beginning_of_week
        @increment_function = :week
      elsif grouping_name == "month"
        @normalize_function = :at_beginning_of_month
        @increment_function = :month
      else
        raise "bad time grouping #{grouping_name}"
      end
      return @normalize_function, @increment_function
    end

    def add_range(start_time, end_time)
      raise "don't do that" if start_time > end_time
      current_time = start_time.send(@normalize_function)
      last_time = end_time.send(@normalize_function)
      while current_time <= last_time
        @data[current_time] ||= 0
        @data[current_time] += 1
        current_time += 1.send(@increment_function)
      end
    end

    def ranged_data(min_time, max_time)
      raise "don't do that" if max_time < min_time
      current_time = min_time.send(@normalize_function)
      last_time = max_time.send(@normalize_function)

      values = []
      while current_time <= last_time
        values << (@data[current_time] || 0)
        current_time += 1.send(@increment_function)
      end
      return values
    end

    def self.time_range(min_time, max_time, grouping_name)
      raise "don't do that" if max_time < min_time
      normalize_function, increment_function = assign_grouping_functions(grouping_name)
      current_time = min_time.send(normalize_function)
      last_time = max_time.send(normalize_function)

      values = []
      while current_time <= last_time
        values << current_time
        current_time += 1.send(increment_function)
      end
      return values
    end
  end
end
