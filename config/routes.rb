Naf::Engine.routes.draw do
  resources :jobs do
    resources :job_affinity_tabs, :except => [:destroy]
  end
  resources :applications, :except => [:destroy] do
    resources :application_schedules, :only => [] do
      resources :application_schedule_affinity_tabs
    end
  end
  resources :machines, :except => [:destroy] do
    resources :machine_affinity_slots
  end
  resources :logger_styles
  resources :logger_names
  resources :affinities

  resources :janitorial_archive_assignments, :controller => "janitorial_assignments", :type => "Naf::JanitorialArchiveAssignment", :except => [:destroy]
  resources :janitorial_create_assignments, :controller => "janitorial_assignments", :type => "Naf::JanitorialCreateAssignment", :except => [:destroy]
  resources :janitorial_drop_assignments, :controller => "janitorial_assignments", :type => "Naf::JanitorialDropAssignment", :except => [:destroy]

  root :to => "jobs#index"
end
