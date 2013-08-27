Naf::Engine.routes.draw do
  resources :historical_jobs do
    resources :historical_job_affinity_tabs, except: [:destroy]
  end

  resources :applications, except: [:destroy] do
    resources :application_schedules, only: [] do
      resources :application_schedule_affinity_tabs
    end
  end

  resources :machines, except: [:destroy] do
    resources :machine_affinity_slots
  end

  resources :machine_runners, only: [:index, :show]
  resources :machine_runner_invocations, only: [:index, :show, :update]
  resources :logger_styles
  resources :logger_names
  resources :affinities

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
