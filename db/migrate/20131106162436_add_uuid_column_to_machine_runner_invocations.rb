class AddUuidColumnToMachineRunnerInvocations < ActiveRecord::Migration

	def up
    execute <<-SQL
      ALTER TABLE #{Naf.schema_name}.machine_runner_invocations ADD COLUMN uuid text unique;
    SQL
	end

	def down
    execute <<-SQL
      ALTER TABLE #{Naf.schema_name}.machine_runner_invocations DROP COLUMN uuid;
    SQL
	end

end
