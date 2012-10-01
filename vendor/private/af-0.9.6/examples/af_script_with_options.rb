module ::Af::Examples
  class AfScriptWithOptions < ::Af::Application
    opt do
      # two switches with no arguments
      opt :baz
      opt :beltch
    end

    # an option with a bunch of parameters
    opt :foo, :argument => :required, :type => :int, :var => :foo, :env => "FOO", :note => "nothing really", :default => 0, :short => "f"
    opt :bar, :argument => :required do |option,argument|
      puts "method evaluation called for :bar, argument: #{argument}"
      argument
    end

    opt :another_option, "some note"

    def work
      puts "baz: #{@baz}"
      puts "bar: #{@bar}"
      opt_error "foo must be less than 100" if @foo >= 100
    end
  end
end

#::Af::Examples::AfScriptWithOptions.run

# run with:

# rails runner path_to_this_file/script_with_options.rb
