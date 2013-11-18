Naf::Engine.routes.draw do
  resources :historical_jobs, except: [:edit] do
    resources :historical_job_affinity_tabs, except: [:destroy]
  end

  resources :applications, except: [:destroy] do
    resources :application_schedules, only: [] do
      resources :application_schedule_affinity_tabs
    end
  end

  resources :machines, except: [:destroy] do
    resources :machine_affinity_slots
    collection do
      get :last_checked_schedule_at
    end
  end

  resources :machine_runners, only: [:index, :show] do
    collection do
      get :runner_count
    end
  end
  resources :machine_runner_invocations, only: [:index, :show, :update] do
    collection do
      get :wind_down_all
    end
  end
  resources :logger_styles
  resources :logger_names
  resources :affinities
  resources :log_parsers, only: [] do
    collection do
      get :logs
    end
  end
  resources :status, only: [:index]
  resources :log_viewer, only: [:index]

  resources :janitorial_archive_assignments, controller: "janitorial_assignments",
                                             type: "Naf::JanitorialArchiveAssignment",
                                             except: [:destroy]
  resources :janitorial_create_assignments, controller: "janitorial_assignments",
                                            type: "Naf::JanitorialCreateAssignment",
                                            except: [:destroy]
  resources :janitorial_drop_assignments, controller: "janitorial_assignments",
                                          type: "Naf::JanitorialDropAssignment",
                                          except: [:destroy]

  match "jobs" => "historical_jobs#index"
  root to: "historical_jobs#index"
end
