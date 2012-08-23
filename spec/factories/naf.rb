require 'factory_girl'

FactoryGirl.define do


  factory :rails_application, :class => ::Naf::Application  do
    association :application_type, :factory => :rails_app_type
    sequence(:title) do |n|
      "Test #{n}"
    end
  end


  factory :rails_app_type, :class => ::Naf::ApplicationType do
    id 1
    script_type_name "rails"
    description "ruby on rails NAF application"
    invocation_method "rails_invocator"
    # Ensure single instantiation
    initialize_with do
      ::Naf::ApplicationType.find_or_initialize_by_id(id)
    end
  end


  factory :bash_command_app_type, :class => ::Naf::ApplicationType do
    id 2
    script_type_name "bash command"
    description "bash command"
    invocation_method "bash_command_invocator"
    # Ensure single instantiation
    initialize_with do 
      ::Naf::ApplicationType.find_or_initialize_by_id(id)
    end
  end

  factory :bash_script_app_type, :class => ::Naf::ApplicationType do
    id 3
    script_type_name "bash script"
    description "bash script"
    invocation_method "bash_script_invocator"
    # Ensure single instantiation
    initialize_with do 
      ::Naf::ApplicationType.find_or_initialize_by_id(id)
    end
  end

  factory :ruby_script_app_type, :class => ::Naf::ApplicationType do
    id 4
    script_type_name "ruby"
    description "ruby script"
    invocation_method "ruby_script_invocator"
    # Ensure single instantiation
    initialize_with do 
      ::Naf::ApplicationType.find_or_initialize_by_id(id)
    end
  end




end
