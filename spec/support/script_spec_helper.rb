module ScriptSpecHelper
  # Run the script defined in a spec's let(:script)
  # It rescues from the SystemExit exception that all scripts raise
  # once they are finished (this is how the runner is setup)

  # Yield to the given block before the script is run
  # This is useful for setup code
  # or if script is an instance, you can write some expectations or stubs
  # Example:
  #
  #   require 'spec_helper'
  #   module Process
  #     describe MyCoolScript do
  #       let(:script) { Process::MyCoolScript.new }
  #       it "should should find five downloads" do
  #         run_script do
  #           script.should_receive(:downloads).and_return(5)
  #         end
  #       end
  #     end
  #   end
  def run_script(*args)
    exit_status = 0
    # Lets not log anything when we run tests of the scripts,
    # especially if we are using Papertrail
    # If any args were passed, set them to ARGV for the script to use.
    #log_level_args = ["--log-configuration-files", "config/logging/af.yml,config/logging/test.yml"]
    log_level_args = ["--log-configuration-files", "config/logging/test.yml"]

    if args.length > 0
      old_args = ARGV[0..-1]
      ARGV[0..-1] = args + log_level_args
    else
      ARGV[0..-1] = log_level_args
    end

    begin
      if block_given?
        yield
      elsif script.is_a?(Class)
        # script is a class, use the normal run method
        script.run
      else
        # script is an instance, run it the way Af runs it.
        # https://github.com/fiksu/af/blob/master/lib/af/application.rb
        script._run
        script._work
      end
    rescue SystemExit => e
      exit_status = e.status
    ensure
      # Reset ARGV if it was changed
      ARGV[0..-1] = old_args if args.length > 0
    end

    exit_status
  end
end
