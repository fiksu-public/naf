require 'factory_girl'

FactoryGirl.define do

  #############################################################
  #######   Jobs  #############################################
  #############################################################

  factory :job_base, class: ::Naf::HistoricalJob do
    association :application_type, factory: :rails_app_type
    association :application_run_group_restriction, factory: :no_limit
  end

  factory :job, parent: :job_base do
    command "::Naf::HistoricalJob.test hello world"
    sequence(:application_run_group_name) { |n| "Run Group #{n}" }
  end

  factory :queued_job, class: ::Naf::QueuedJob do
    association :historical_job, factory: :job
    association :application_type, factory: :rails_app_type
    association :application_run_group_restriction, factory: :no_limit
    command "::Naf::QueuedJob.test hello world"
  end

  factory :running_job_base, class: ::Naf::RunningJob do
    association :historical_job, factory: :job
    association :started_on_machine, factory: :machine
    association :application_type, factory: :rails_app_type
    association :application_run_group_restriction, factory: :no_limit
    command "::Naf::RunningJob.test hello world"
  end

  factory :scheduled_job, parent: :job do
    association :application, factory: :scheduled_application
  end

  factory :job_picked_by_machine, parent: :job do
    association :started_on_machine, factory: :machine
  end

  factory :failed_to_start_job, parent: :job_picked_by_machine do
    failed_to_start true
  end

  factory :running_job, parent: :job_picked_by_machine do
    started_at Time.zone.now
  end

  factory :terminating_job, parent: :running_job do
    request_to_terminate true
    finished_at nil
  end

  factory :canceled_job, parent: :running_job do
    request_to_terminate true
    finished_at Time.zone.now
  end

  factory :finished_job, parent: :job_picked_by_machine do
    started_at Time.zone.now - 3.minutes
    finished_at Time.zone.now
    exit_status 0
  end

  factory :job_with_error, parent: :finished_job do
    exit_status 1
  end

  factory :job_with_signal, parent: :job_picked_by_machine do
    termination_signal 1
  end

  factory :stale_job, parent: :job_picked_by_machine do
    created_at  Time.zone.now - 1.week - 3.days - 5.minutes
    started_at  Time.zone.now - 1.week - 3.days - 3.minutes
    finished_at Time.zone.now - 1.week - 3.days
  end

  factory :scheduled_picked_job, parent: :job_picked_by_machine do
    association :application, factory: :scheduled_application
  end

  factory :scheduled_running_job, parent: :scheduled_picked_job do
    started_at Time.zone.now
  end

  factory :scheduled_finished_job, parent: :scheduled_picked_job do
    started_at Time.zone.now - 3.minutes
    finished_at Time.zone.now
  end

  factory :historical_job_prerequesite, class: ::Naf::HistoricalJobPrerequisite do
    association :historical_job, factory: :job
    association :prerequisite_historical_job, factory: :job
  end

  #############################################################
  #######   Machines  #########################################
  #############################################################

  factory :machine_base, class: ::Naf::Machine do
    sequence(:short_name) { |n| "short_name#{n}" }
  end

  factory :machine, parent: :machine_base do
    id 1
    server_address "0.0.0.1"
    initialize_with do
      ::Naf::Machine.find_or_initialize_by_id(id)
    end
  end

  factory :machine_two, parent: :machine_base do
    id 2
    server_address "0.0.0.2"
    initialize_with do
      ::Naf::Machine.find_or_initialize_by_id(id)
    end
  end

  #############################################################
  #######   Machine Runners  ##################################
  #############################################################

  factory :machine_runner, class: ::Naf::MachineRunner do
    association :machine, factory: :machine
    sequence(:runner_cwd) { |n| "/proc/1/#{n}" }
  end

  #############################################################
  #######   Machine Runner Invocations  #######################
  #############################################################

  factory :machine_runner_invocation, class: ::Naf::MachineRunnerInvocation do
    association :machine_runner, factory: :machine_runner
    sequence(:pid) { |n| n }
    commit_information '123456'
    branch_name 'branch'
    repository_name 'app/example'
    deployment_tag "20130101_1200"
  end

  #############################################################
  #######   Applications ######################################
  #############################################################

  factory :application_base, class: ::Naf::Application  do
    association :application_type, factory: :rails_app_type
    sequence(:short_name) { |n| "short_name#{n}" }
  end

  factory :application, parent: :application_base do
    sequence(:command) { |n| "::Naf::HistoricalJob.test hello_#{n}" }
    sequence(:title) { |n| "Test #{n}" }

    factory :scheduled_application do
      after(:create) do |application|
        create_list(:schedule, 1, application: application)
      end
    end
  end

  #############################################################
  #######   Application Schedules ############ ################
  #############################################################

  factory :schedule_base, class: ::Naf::ApplicationSchedule do
    association :application, factory: :application
    association :application_run_group_restriction, factory: :no_limit
    association :run_interval_style, factory: :run_interval_style
    run_interval 0
  end

  factory :schedule, parent: :schedule_base do
    sequence(:application_run_group_name) { |n| "Run Group #{n}" }
  end

  #############################################
  #######   Run Interval Style ################
  #############################################

  factory :run_interval_style, class: ::Naf::RunIntervalStyle do
    name 'at beginning of day'
  end

  #############################################################
  #######   Application Schedules Prerequisite ################
  #############################################################

  factory :schedule_prerequisite, class: ::Naf::ApplicationSchedulePrerequisite do
    association :application_schedule, factory: :schedule
    association :prerequisite_application_schedule, factory: :schedule
  end

  #############################################################
  #######   Application Run Group Restrictions ################
  #############################################################

  factory :no_limit, class: ::Naf::ApplicationRunGroupRestriction do
    id 1
    application_run_group_restriction_name "no limit"
    # Ensure single creation
    initialize_with do
      ::Naf::ApplicationRunGroupRestriction.find_or_initialize_by_id(id)
    end
  end

  factory :limited_per_machine, class: ::Naf::ApplicationRunGroupRestriction do
    id 2
    application_run_group_restriction_name "limited per machine"
    # Ensure single creation
    initialize_with do
      ::Naf::ApplicationRunGroupRestriction.find_or_initialize_by_id(id)
    end
  end

  factory :limited_per_all_machines, class: ::Naf::ApplicationRunGroupRestriction do
    id 3
    application_run_group_restriction_name "limited per all machines"
    # Ensure single creation
    initialize_with do
      ::Naf::ApplicationRunGroupRestriction.find_or_initialize_by_id(id)
    end
  end

  factory :run_group_restriction, class: ::Naf::ApplicationRunGroupRestriction do
    id 4
    application_run_group_restriction_name "restriction"
  end

  #############################################################
  #######   Application Types #################################
  #############################################################

  factory :rails_app_type, class: ::Naf::ApplicationType do
    id 1
    script_type_name "rails"
    description "ruby on rails NAF application"
    invocation_method "rails_invocator"
    # Ensure single creation
    initialize_with do
      ::Naf::ApplicationType.find_or_initialize_by_id(id)
    end
  end

  factory :bash_command_app_type, class: ::Naf::ApplicationType do
    id 2
    script_type_name "bash command"
    description "bash command"
    invocation_method "bash_command_invocator"
    # Ensure single creation
    initialize_with do
      ::Naf::ApplicationType.find_or_initialize_by_id(id)
    end
  end

  factory :bash_script_app_type, class: ::Naf::ApplicationType do
    id 3
    script_type_name "bash script"
    description "bash script"
    invocation_method "bash_script_invocator"
    # Ensure single creation
    initialize_with do
      ::Naf::ApplicationType.find_or_initialize_by_id(id)
    end
  end

  factory :ruby_script_app_type, class: ::Naf::ApplicationType do
    id 4
    script_type_name "ruby"
    description "ruby script"
    invocation_method "ruby_script_invocator"
    # Ensure single creation
    initialize_with do
      ::Naf::ApplicationType.find_or_initialize_by_id(id)
    end
  end

  #############################################################
  #######   Affinities      ###################################
  #############################################################

  factory :normal_affinity, class: ::Naf::Affinity do
    id 1
    association :affinity_classification, factory: :purpose_affinity_classification
    affinity_name "normal"
    affinity_short_name "short_name"
    # Ensure single creation
    initialize_with do
      ::Naf::Affinity.find_or_initialize_by_id(id)
    end
  end

  factory :canary_affinity, class: ::Naf::Affinity do
    id 2
    association :affinity_classification, factory: :purpose_affinity_classification
    affinity_name "canary"
    # Ensure single creation
    initialize_with do
      ::Naf::Affinity.find_or_initialize_by_id(id)
    end
  end

  factory :perennial_affinity, class: ::Naf::Affinity do
    id 3
    association :affinity_classification, factory: :purpose_affinity_classification
    affinity_name "perennial"
    # Ensure single creation
    initialize_with do
      ::Naf::Affinity.find_or_initialize_by_id(id)
    end
  end

  factory :machine_affinity, class: ::Naf::Affinity do
    id 4
    association :affinity_classification, factory: :machine_affinity_classification
    affinity_name "machine"
    # Ensure single creation
    initialize_with do
      ::Naf::Affinity.find_or_initialize_by_id(id)
    end
  end

  factory :affinity, class: ::Naf::Affinity do
    association :affinity_classification, factory: :purpose_affinity_classification
    sequence(:affinity_name) do |n|
      "Affinity #{n}"
    end
  end

  #############################################################
  #######   Affinity Classifications  #########################
  #############################################################

  factory :location_affinity_classification, class: ::Naf::AffinityClassification do
    id 1
    affinity_classification_name "location"
    initialize_with do
      ::Naf::AffinityClassification.find_or_initialize_by_id(id)
    end
  end

  factory :purpose_affinity_classification, class: ::Naf::AffinityClassification do
    id 2
    affinity_classification_name "purpose"
    initialize_with do
      ::Naf::AffinityClassification.find_or_initialize_by_id(id)
    end
  end

  factory :application_affinity_classification, class: ::Naf::AffinityClassification do
    id 3
    affinity_classification_name "application"
    initialize_with do
      ::Naf::AffinityClassification.find_or_initialize_by_id(id)
    end
  end

  factory :weight_affinity_classification, class: ::Naf::AffinityClassification do
    id 4
    affinity_classification_name "weight"
    initialize_with do
      ::Naf::AffinityClassification.find_or_initialize_by_id(id)
    end
  end

  factory :machine_affinity_classification, class: ::Naf::AffinityClassification do
    id 5
    affinity_classification_name "machine"
    initialize_with do
      ::Naf::AffinityClassification.find_or_initialize_by_id(id)
    end
  end

  factory :affinity_classification, class: ::Naf::AffinityClassification do
    sequence(:affinity_classification_name) { |n| "affinity_classification_#{n}" }
  end

  #############################################################
  #######   Affinity Tabs and Slots   #########################
  #############################################################

  # Job Affinity Tabs

  factory :job_affinity_tab_base, class: ::Naf::HistoricalJobAffinityTab do
    association :historical_job, factory: :job
  end

  factory :normal_job_affinity_tab, parent: :job_affinity_tab_base do
    association :affinity, factory: :normal_affinity
  end

  factory :perennial_job_affinity_tab, parent: :job_affinity_tab_base do
    association :affinity, factory: :perennial_affinity
  end

  factory :canary_job_affinity_tab, parent: :job_affinity_tab_base do
    association :affinity, factory: :canary_affinity
  end

  factory :weight_job_affinity_tab, parent: :job_affinity_tab_base do
    association :affinity, factory: :weight_affinity
  end

  factory :machine_job_affinity_tab, parent: :job_affinity_tab_base do
    association :affinity, factory: :machine_affinity
  end

  # Application Schedule Affinity Tabs

  factory :app_schedule_affinity_tab_base, class: ::Naf::ApplicationScheduleAffinityTab do
    association :application_schedule, factory: :schedule
  end

  factory :normal_app_schedule_affinity_tab, parent: :app_schedule_affinity_tab_base do
    association :affinity, factory: :normal_affinity
  end

  factory :canary_app_schedule_affinity_tab, parent: :app_schedule_affinity_tab_base do
    association :affinity, factory: :canary_affinity
  end

  # Machine Affinity Slots

  factory :machine_affinity_slot_base, class: ::Naf::MachineAffinitySlot do
    association :machine, factory: :machine
  end

  factory :normal_machine_affinity_slot, parent: :machine_affinity_slot_base do
    association :affinity, factory: :normal_affinity
  end

  factory :required_perennial_slot, parent: :machine_affinity_slot_base do
    association :affinity, factory: :perennial_affinity
    required true
  end

  factory :canary_slot, parent: :machine_affinity_slot_base do
    association :affinity, factory: :canary_affinity
  end

  factory :required_canary_slot, parent: :machine_affinity_slot_base do
    association :affinity, factory: :canary_affinity
    required true
  end

  ##################################################
  #######   Logger Level   #########################
  ##################################################

  factory :logger_level, class: ::Naf::LoggerLevel do
    sequence(:level) { |n| "level#{n}" }
  end

  #################################################
  #######   Logger Name   #########################
  #################################################

  factory :logger_name, class: ::Naf::LoggerName do
    sequence(:name) { |n| "name#{n}" }
  end

  ##################################################
  #######   Logger Style   #########################
  ##################################################

  factory :logger_style, class: ::Naf::LoggerStyle do
    sequence(:name) { |n| "name#{n}" }
  end

  ######################################################
  #######   Logger Style Name  #########################
  ######################################################

  factory :logger_style_name, class: ::Naf::LoggerStyleName do
    association :logger_level, factory: :logger_level
    association :logger_name, factory: :logger_name
    association :logger_style, factory: :logger_style
  end

end
