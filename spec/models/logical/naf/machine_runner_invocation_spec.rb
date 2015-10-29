require 'spec_helper'

module Logical
  module Naf

    describe MachineRunnerInvocation do

    	let!(:machine_runner) { FactoryGirl.create(:machine_runner) }
    	let!(:machine) { ::Logical::Naf::Machine.new(machine_runner.machine) }
    	let!(:invocation1) { FactoryGirl.create(:machine_runner_invocation, machine_runner: machine_runner) }
    	let!(:invocation2) { FactoryGirl.create(:machine_runner_invocation, machine_runner: machine_runner) }
    	let!(:invocations) {
    		[[invocation1.id,
    			invocation1.created_at.to_s,
    			invocation1.machine_runner_id,
    			[machine.id, machine.name.to_s],
    			invocation1.pid,
    			invocation1.status.gsub('-', ' ').split.map(&:capitalize).join(' '),
    			invocation1.commit_information,
    			invocation1.deployment_tag,
    			invocation1.repository_name],
    		 [invocation2.id,
    		 	invocation2.created_at.to_s,
    		 	invocation2.machine_runner_id,
    		 	[machine.id, machine.name.to_s],
    		 	invocation2.pid,
    			invocation2.status.gsub('-', ' ').split.map(&:capitalize).join(' '),
    			invocation2.commit_information,
    			invocation2.deployment_tag,
    			invocation2.repository_name]]
    	}

    	describe '#to_array' do
    		it 'return invocation information in correct order' do
    			expect(::Logical::Naf::MachineRunnerInvocation.to_array(0, 'asc', nil)).to eq(invocations)
    		end
    	end

    end
  end
end
