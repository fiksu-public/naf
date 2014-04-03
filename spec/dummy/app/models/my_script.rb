class MyScript < ::Process::Naf::Application
  opt :thing, default: "world"


  def work
    logger.info("Hello #{@thing}!")
  end
end
