require 'spec_helper'

module Logical
  module Naf

    describe ApplicationSchedule do

      describe '#exact_time_of_day' do

        #----------------
        # *** Methods ***
        #++++++++++++++++

        def update_schedule(run_interval)
          schedule.run_interval = run_interval
          schedule.save

          ::Logical::Naf::ApplicationSchedule.new(schedule)
        end

        #------------------------
        # *** Shared Examples ***
        #++++++++++++++++++++++++

        shared_examples 'displays the hour correctly' do |run_interval, time|
          it { expect(update_schedule(run_interval).exact_time_of_day).to eq(time) }
        end

        let!(:schedule) { FactoryGirl.create(:schedule_base) }

        it_should_behave_like 'displays the hour correctly', 10, '12:10 AM'
        it_should_behave_like 'displays the hour correctly', 480, '08:00 AM'
        it_should_behave_like 'displays the hour correctly', 2880, '12:00 AM'
        it_should_behave_like 'displays the hour correctly', 20160, '12:00 AM'
        it_should_behave_like 'displays the hour correctly', 46080, '12:00 AM'

      end
    end

  end
end
