Naf.configure do |config|

  config.schema_name = 'naf'

  # Seting up Papertrail links:
  # config.papertrail_group_id = ...

  # Allow jobs page to refresh
  config.job_refreshing = true
  config.jobs_per_page = 50

end

