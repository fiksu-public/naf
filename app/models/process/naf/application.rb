module Process::Naf
  class Application < ::Af::Application
    opt :naf_application_id, :env => "NAF_APPLICATION_ID", :type => :int, :default => "unknown"

    def log4r_name_suffix
      return ":[#{@naf_application_id}]"
    end

    def work
    end
  end
end
