Naf::Engine.routes.draw do
  resources :jobs
  resources :job_affinity_tabs
  resources :application_schedules
  resources :application_schedule_affinity_tabs
  resources :application_types
  resources :machines
  resources :machine_affinity_slots
  resources :affinities
  resources :affinity_classifications
  resources :application_run_groups
  resources :application_run_group_restrictions
  resources :applications
  root :to => "applications#index"
end
