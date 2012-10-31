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
  resources :affinities
  root :to => "jobs#index"
end
