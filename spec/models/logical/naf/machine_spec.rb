require 'spec_helper'

module Logical
  module Naf

    describe Machine do
      let!(:physical_machine) { FactoryGirl.create(:machine, server_name: 'example.com')  }
      let!(:physical_machine_two) { FactoryGirl.create(:machine_two) }
      let!(:logical_machine) { ::Logical::Naf::Machine.new(physical_machine) }
      let(:columns) { [:id,
                       :server_name,
                       :server_address,
                       :server_note,
                       :enabled,
                       :process_pool_size,
                       :last_checked_schedules_at,
                       :last_seen_alive_at,
                       :log_level,
                       :affinities,
                       :marked_down] }

      describe '#self.all' do
        it 'return an array of logical wrappers around machines' do
          expect(::Logical::Naf::Machine.all.map(&:id).sort).to eq([physical_machine.id, physical_machine_two.id])
        end
      end

      describe '#process_pool_size' do
        it 'return the correct value' do
          physical_machine.thread_pool_size = 5
          expect(logical_machine.process_pool_size).to eq(5)
        end
      end

      describe '#last_checked_schedules_at' do
        it 'render result nicely' do
          physical_machine.mark_checked_schedule
          expect(logical_machine).to receive(:time_ago_in_words).and_return('')
          expect(logical_machine.last_checked_schedules_at.split(',').first).to match(/ago$/)
        end
      end

      describe '#last_seen_alive_at' do
        it 'render result nicely' do
          physical_machine.mark_alive
          expect(logical_machine).to receive(:time_ago_in_words).and_return('')
          expect(logical_machine.last_seen_alive_at.split(',').first).to match(/ago$/)
        end
      end

      describe '#to_hash' do
        it 'return with the specified columns' do
          expect(logical_machine.to_hash.keys).to eq(columns)
        end
      end

      describe '#affinities' do
        let!(:slot) { FactoryGirl.create(:normal_machine_affinity_slot, machine: physical_machine) }

        it 'return short_name and affinity_parameter when both are present' do
          slot.update_attributes!(affinity_parameter: 5)
          expect(logical_machine.affinities).to eq('short_name(5.0)')
        end

        it 'return short_name when affinity_parameter is not present' do
          expect(logical_machine.affinities).to eq('short_name')
        end

        it 'return classification and affinity names as last resort' do
          slot.affinity.update_attributes!(affinity_short_name: nil)
          expect(logical_machine.affinities).to eq('purpose_normal')
        end
      end

      describe '#name' do
        it 'return short_name when present' do
          physical_machine.short_name = 'short_name1'
          expect(logical_machine.name).to eq('short_name1')
        end

        it 'return server_name when short_name is not present' do
          physical_machine.short_name = nil
          expect(logical_machine.name).to eq('example.com')
        end

        it 'return server_address when server_name is not present' do
          physical_machine.short_name = nil
          physical_machine.server_name = nil
          expect(logical_machine.name).to eq('0.0.0.1')
        end
      end

      describe '#status' do
        let!(:runner) { FactoryGirl.create(:machine_runner, machine: physical_machine) }
        let!(:invocation) { FactoryGirl.create(:machine_runner_invocation, machine_runner: runner) }

        it 'report correctly when runner is up' do
          hash = {
            server_name: logical_machine.name,
            status: 'Good',
            notes: ''
          }
          expect(logical_machine.status).to eq(hash)
        end

        it 'report correctly when runner is down' do
          hash = {
            server_name: logical_machine.name,
            status: 'Bad',
            notes: 'Runner down'
          }
          invocation.update_attributes!(wind_down_at: Time.zone.now, dead_at: Time.zone.now)
          expect(logical_machine.status).to eq(hash)
        end
      end

      describe '#runner' do
        it 'return server_name when present' do
          expect(logical_machine.runner).to eq('example.com')
        end

        it 'return server_address when server_address is not present' do
          physical_machine.server_name = nil
          expect(logical_machine.runner).to eq('0.0.0.1')
        end
      end

    end

  end
end
