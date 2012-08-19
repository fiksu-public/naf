Naf::Engine.routes.draw do
  resources :jobs do
    resources :job_affinity_tabs
  end
  resources :applications do
    resources :application_schedules do
      resources :application_schedule_affinity_tabs
    end
  end
  resources :application_types
  resources :machines do
    resources :machine_affinity_slots
  end
  resources :affinities
  resources :affinity_classifications
  resources :application_run_group_restrictions
  root :to => "jobs#index"
end
