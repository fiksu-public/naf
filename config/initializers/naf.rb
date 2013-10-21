module Naf
	DEFAULT_PAGE_OPTIONS = [10, 20, 50, 100, 250, 500, 750, 1000, 1500, 2000]
	LOGGING_ARCHIVE_DIRECTORY = "/archive"
	if ['test', 'development'].include?(Rails.env)
		LOGGING_ROOT_DIRECTORY = 'mnt'
	else
		LOGGING_ROOT_DIRECTORY = '/var/log/mnt'
	end
end
