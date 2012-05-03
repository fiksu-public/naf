module Af::AdvisoryLocker
  def self.included(base)
    base.extend(ClassMethods)
  end

  def advisory_lock
    self.class.lock_record(id)
  end

  def advisory_try_lock
    self.class.try_lock_record(id)
  end

  def advisory_unlock
    self.class.unlock_record(id)
  end

  module ClassMethods
    def lock_record(id)
      locked = uncached do
        find_by_sql(["select pg_advisory_lock((SELECT oid FROM pg_class WHERE relname = ?)::integer, ?)",
                              table_name, id])[0].pg_advisory_lock == "t"
      end
      # puts("#{locked} = #{Process.pid}.lock(#{table_name}, #{id})")
      locked
    end

    def try_lock_record(id)
      locked = uncached do
        find_by_sql(["select pg_try_advisory_lock((SELECT oid FROM pg_class WHERE relname = ?)::integer, ?)",
                              table_name, id])[0].pg_try_advisory_lock == "t"
      end
      # puts("#{locked} = #{Process.pid}.lock(#{table_name}, #{id})")
      locked
    end

    def unlock_record(id)
      unlocked = uncached do
        find_by_sql(["select pg_advisory_unlock((SELECT oid FROM pg_class WHERE relname = ?)::integer, ?)",
                                table_name, id])[0].pg_advisory_unlock == "t"
      end
      # puts("#{unlocked} = #{Process.pid}.unlock(#{table_name}, #{id})")
      unlocked
    end
  end
end
