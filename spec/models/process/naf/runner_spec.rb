require 'spec_helper'

module Process::Naf
  describe Runner do
    let!(:runner) { ::Process::Naf::Runner.new }

    describe '#memory_available_to_spawn?' do
      before do
        expect(Facter).to receive(:memorysize_mb).and_return(100.0)
        runner.instance_variable_set(:@minimum_memory_free, 15.0)
      end

      it 'return true when there is available memory' do
        expect(Facter).to receive(:memoryfree_mb).and_return(20.0)
        expect(runner.memory_available_to_spawn?).to be_truthy
      end

      it 'return true when there is available memory' do
        expect(Facter).to receive(:memoryfree_mb).and_return(10.0)
        expect(runner).to receive(:sreclaimable_memory).and_return(0.0)
        expect(runner.memory_available_to_spawn?).to be_falsey
      end
    end

  end
end
