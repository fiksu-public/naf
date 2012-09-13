class MyScript < ::Process::Naf::Application
  opt :thing, :default => "world"


  def work
    puts logger.inspect
    logger.info("Hello #{@thing}!")
  end
end
