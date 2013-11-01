module Naf
	DEFAULT_PAGE_OPTIONS = [10, 20, 50, 100, 250, 500, 750, 1000, 1500, 2000]
	LOGGING_ARCHIVE_DIRECTORY = "/archive"
	if ['test', 'development'].include?(Rails.env)
		LOGGING_ROOT_DIRECTORY = 'var/log/'
	else
		LOGGING_ROOT_DIRECTORY = '/var/log/'
	end

  NAF_DATABASE_HOSTNAME = Rails.configuration.database_configuration[Rails.env]['host'].present? ?
    Rails.configuration.database_configuration[Rails.env]['host'] : 'localhost'
  NAF_DATABASE = Rails.configuration.database_configuration[Rails.env]['database']
  NAF_SCHEMA = ::Naf.schema_name
  PREFIX_PATH = "#{LOGGING_ROOT_DIRECTORY}/naf/#{NAF_DATABASE_HOSTNAME}/#{NAF_DATABASE}/#{NAF_SCHEMA}"

end
