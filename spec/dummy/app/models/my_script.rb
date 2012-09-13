class MyScript < ::Process::Naf::Application
  opt :thing, :default => "world"

  def pre_work
  end

  def work
    logger.info("Hello #{@thing}!")
  end
end
