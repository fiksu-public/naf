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
          ::Logical::Naf::Machine.all.map(&:id).should == [physical_machine.id, physical_machine_two.id]
        end
      end

      describe '#process_pool_size' do
        it 'return the correct value' do
          physical_machine.thread_pool_size = 5
          logical_machine.process_pool_size.should == 5
        end
      end

      describe '#last_checked_schedules_at' do
        it 'render result nicely' do
          physical_machine.mark_checked_schedule
          logical_machine.should_receive(:time_ago_in_words).and_return('')
          logical_machine.last_checked_schedules_at.split(',').first.should =~ /ago$/
        end
      end

      describe '#last_seen_alive_at' do
        it 'render result nicely' do
          physical_machine.mark_alive
          logical_machine.should_receive(:time_ago_in_words).and_return('')
          logical_machine.last_seen_alive_at.split(',').first.should =~ /ago$/
        end
      end

      describe '#to_hash' do
        it 'return with the specified columns' do
          logical_machine.to_hash.keys.should == columns
        end
      end

      describe '#affinities' do
        let!(:slot) { FactoryGirl.create(:normal_machine_affinity_slot, machine: physical_machine) }

        it 'return short_name and affinity_parameter when both are present' do
          slot.update_attributes!(affinity_parameter: 5)
          logical_machine.affinities.should == 'short_name(5.0)'
        end

        it 'return short_name when affinity_parameter is not present' do
          logical_machine.affinities.should == 'short_name'
        end

        it 'return classification and affinity names as last resort' do
          slot.affinity.update_attributes!(affinity_short_name: nil)
          logical_machine.affinities.should == 'purpose_normal'
        end
      end

      describe '#name' do
        it 'return short_name when present' do
          physical_machine.short_name = 'short_name1'
          logical_machine.name.should == 'short_name1'
        end

        it 'return server_name when short_name is not present' do
          physical_machine.short_name = nil
          logical_machine.name.should == 'example.com'
        end

        it 'return server_address when server_name is not present' do
          physical_machine.short_name = nil
          physical_machine.server_name = nil
          logical_machine.name.should == '0.0.0.1'
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
          logical_machine.status.should == hash
        end

        it 'report correctly when runner is down' do
          hash = {
            server_name: logical_machine.name,
            status: 'Bad',
            notes: 'Runner down'
          }
          invocation.update_attributes!(wind_down_at: Time.zone.now, dead_at: Time.zone.now)
          logical_machine.status.should == hash
        end
      end

      describe '#runner' do
        it 'return server_name when present' do
          logical_machine.runner.should == 'example.com'
        end

        it 'return server_address when server_address is not present' do
          physical_machine.server_name = nil
          logical_machine.runner.should == '0.0.0.1'
        end
      end

    end

  end
end
