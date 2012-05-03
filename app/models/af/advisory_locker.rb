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
    def table_oid
      if @table_oid.nil?
        sql_table_components = table_name.split('.')
        if sql_table_components.length == 1
          sql_table_components.prepend('public')
        end
        sql = <<-SQL
         SELECT
           pg_class.oid
         FROM
           pg_class,pg_namespace
         WHERE
           pg_namespace.nspname = ? and
           pg_class.relnamespace = pg_namespace.oid and
           pg_class.relname = ?
        SQL
        @table_oid = find_by_sql([sql, *sql_table_components]).first.oid.to_i
      end
      return @table_oid
    end

    def lock_record(id)
      locked = uncached do
        find_by_sql(["select pg_advisory_lock(?, ?)", table_oid, id])[0].pg_advisory_lock == "t"
      end
      # puts("#{locked} = #{Process.pid}.lock(#{table_name}, #{id})")
      return locked
    end

    def try_lock_record(id)
      locked = uncached do
        find_by_sql(["select pg_try_advisory_lock(?, ?)", table_oid, id])[0].pg_try_advisory_lock == "t"
      end
      # puts("#{locked} = #{Process.pid}.lock(#{table_name}, #{id})")
      return locked
    end

    def unlock_record(id)
      unlocked = uncached do
        find_by_sql(["select pg_advisory_unlock(?, ?)", table_oid, id])[0].pg_advisory_unlock == "t"
      end
      # puts("#{unlocked} = #{Process.pid}.unlock(#{table_name}, #{id})")
      return unlocked
    end
  end
end
