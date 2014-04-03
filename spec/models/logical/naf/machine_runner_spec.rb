require 'spec_helper'

module Logical
  module Naf

    describe MachineRunner do

    	let!(:machine_runner1) { FactoryGirl.create(:machine_runner) }
      let!(:machine_runner2) { FactoryGirl.create(:machine_runner) }
    	let!(:machine) { ::Logical::Naf::Machine.new(machine_runner1.machine) }
    	let!(:invocation1) { FactoryGirl.create(:machine_runner_invocation, machine_runner: machine_runner1) }
    	let!(:invocation2) { FactoryGirl.create(:machine_runner_invocation, machine_runner: machine_runner2) }
    	let!(:invocations) {
    		[[machine_runner1.id,
          machine_runner1.created_at.to_s,
          machine.id,
          machine_runner1.runner_cwd,
          invocation1.id,
          invocation1.pid,
          invocation1.status.gsub('-', ' ').split.map(&:capitalize).join(' '),
          0,
          ''],
         [machine_runner2.id,
          machine_runner2.created_at.to_s,
          machine.id,
          machine_runner2.runner_cwd,
          invocation2.id,
          invocation2.pid,
          invocation2.status.gsub('-', ' ').split.map(&:capitalize).join(' '),
          0,
          '']]
    	}

    	describe '#to_array' do
    		it 'return invocation information in correct order' do
    			::Logical::Naf::MachineRunner.to_array(0, 'asc').should == invocations
    		end
    	end

    end
  end
end
