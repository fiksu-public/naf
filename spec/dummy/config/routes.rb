Rails.application.routes.draw do
  mount Naf::Engine, at: "/job_system"

  root to: redirect("/job_system")
end
