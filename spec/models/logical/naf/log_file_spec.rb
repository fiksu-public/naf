require 'spec_helper'

module Logical
  module Naf
    describe LogFile do

      before(:all) do
        Timecop.freeze(Time.zone.now)
      end

      after(:all) do
        Timecop.return
        `rm -rf log_spec/`
      end

      let!(:log_file) { ::Logical::Naf::LogFile.new('log_spec') }
      let!(:time) { Time.zone.now }
      let!(:log_line) {
        JSON.pretty_generate({
          line_number: 1,
          output_time: time.strftime("%Y-%m-%d %H:%M:%S.%L"),
          message: 'test message'
        })
      }

    	describe '<<' do
        before do
          log_file << 'test message'
        end

        it 'encapsulate the message in JSON format' do
          expect(log_file.lines_cache).to eq(log_line)
        end

        it 'increment the line_number' do
          expect(log_file.line_number).to eq(2)
        end
    	end

    	describe 'write' do
        before do
          log_file.open
          log_file << 'test message'
          log_file.write
        end

        it 'clear the lines_cache' do
          expect(log_file.lines_cache).to eq('')
        end

        it 'save the logs to the file' do
          expect(File.open(log_file.file.path, 'r').read).to eq(log_line)
        end
    	end

    	describe 'flush' do
        before do
          log_file.open
          log_file.file.write('test message')
          log_file.flush
        end

        it 'update the file with content written' do
          expect(File.open(log_file.file.path, 'r').read).to eq('test message')
        end
    	end

    	describe 'open' do
        before do
          log_file.open
        end

        it 'create the file path' do
          expect(log_file.file.path).to eq("log_spec/1_#{time.strftime('%Y%m%d_%H%M%S')}.json")
        end
    	end

    	describe 'close' do
        before do
          log_file.open
          log_file.close
        end

        it 'close the file stream' do
          expect(log_file.file).to eq(nil)
        end
    	end

    	describe 'check_file_size' do
        before do
          log_file.open
          log_file << 'test message'
          log_file.write
          stub_const('::Logical::Naf::LogFile::LOG_MAX_SIZE', 1)
          log_file.check_file_size
        end

        it 'create a new file when size > LOG_MAX_SIZE' do
          expect(log_file.file.path).to eq("log_spec/2_#{time.strftime('%Y%m%d_%H%M%S')}.json")
        end
    	end

    end
  end
end
