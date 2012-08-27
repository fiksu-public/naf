Rails.application.routes.draw do
  mount Naf::Engine => "/job_system"
  mount Naf::Engine, :at => "/job_system"

end
