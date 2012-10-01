Rails.application.routes.draw do
  mount Naf::Engine, :at => "/job_system"

  root :to => "Naf::jobs#index"
end
