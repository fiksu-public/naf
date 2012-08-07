Naf::Engine.routes.draw do
  resources :application_schedules
  root :to => redirect("/job_system/application_schedules")
end
