module ::Af::Examples
  class ScriptWithOptions < ::Af::Application
    opt do
      opt :baz
      opt :beltch
    end

    opt :foo, :argument => :required, :type => :int, :var => :foo, :env => "FOO", :note => "nothing really", :default => 0, :short => "f"
    opt :bar do |option,argument|
    end

    opt :another_option, "some note"

    def work
      puts "baz: #{@baz}"
      opt_error "foo must be less than 100" if @foo >= 100
    end
  end
end

#::Af::Examples::ScriptWithOptions.run

# run with:

# rails runner path_to_this_file/script_with_options.rb
