require 'spec_helper'

module Process::Naf
  describe Runner do
    let!(:runner) { ::Process::Naf::Runner.new }

    describe '#memory_available_to_spawn?' do
      before do
        Facter.should_receive(:memorysize_mb).and_return(100.0)
        runner.instance_variable_set(:@minimum_memory_free, 15.0)
      end

      it 'return true when there is available memory' do
        Facter.should_receive(:memoryfree_mb).and_return(20.0)
        runner.memory_available_to_spawn?.should be_true
      end

      it 'return true when there is available memory' do
        Facter.should_receive(:memoryfree_mb).and_return(10.0)
        runner.memory_available_to_spawn?.should be_false
      end
    end

  end
end
