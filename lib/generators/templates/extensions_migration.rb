# Monkey patch for ActiveRecord::Migration that provides a class method named sql
# for executing a multiline String of SQL within a migration.  Originally written
# by Artur.
module ActiveRecord
  class Migration

    STRING_SEPARATOR_REGEXP = /\$(|\_)\$/
    COMMENT_REGEXP = /^--/

    # Multiline execute for running arbitrary SQL.
    # @param [String] string sql string to execute.
    # @raise [RuntimeError] SQL parsing error
    def self.sql(string)
      query = ''
      in_func = false

      string.each_line { |str|
        str.strip!
        query << str.strip << "\n" unless str.blank? || (str =~ COMMENT_REGEXP)

        in_func = !in_func if str =~ STRING_SEPARATOR_REGEXP
        if !in_func && query =~ /;\n$/
          execute query.chomp
          query = ''
        end
      }

      raise "SQL Parsing Error: #{query} <-" unless query.blank?
    end

    # In Rails 3.1, the up and down methods were changed from class to instance methdos,
    # so this provides compatibility for these new migrations.
    def sql(string)
      self.class.sql(string)
    end

  end
end
