Naf::Engine.routes.draw do
  resources :jobs do
    resources :job_affinity_tabs
  end
  resources :applications do
    resources :application_schedules do
      resources :application_schedule_affinity_tabs
    end
  end
  resources :machines do
    resources :machine_affinity_slots
  end
  resources :affinities
  root :to => "jobs#index"
end
