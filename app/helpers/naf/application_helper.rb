module Naf
  module ApplicationHelper

    DESTROY_BLOCKED_RESOURCES = ["jobs"]
    READ_ONLY_RESOURCES = ["application_types", "application_run_group_restrictions"]
    CREATE_BLOCKED_RESOURCES = ["jobs"]
    ALL_RESOURCES = [ "jobs", "job_affinity_tabs", "applications", "application_schedules", "application_schedule_affinity_tabs",
                      "machines", "machine_affinity_slots", "affinities", "affinity_classifications","application_run_groups", 
                      "application_run_group_restrictions", "application_types"]

    def tabs
      ALL_RESOURCES
    end

    def generate_index_link(name)
      link_to name.split('_').map(&:capitalize).join(' '), {:controller => name, :action => 'index'}
    end

    def generate_create_link
      return "" if READ_ONLY_RESOURCES.include?(controller_name) or CREATE_BLOCKED_RESOURCES.include?(controller_name)
      link_to "Create new #{model_name}", {:controller => controller_name, :action => 'new'}
    end

    def model_name
      name_pieces = controller_name.split('_')
      name_pieces[name_pieces.size - 1] = name_pieces.last.singularize
      name_pieces.map(&:capitalize).join(' ')
    end

    def make_header(attribute)
      attribute.to_s.split('_').map(&:capitalize).join(' ')
    end

    def generate_edit_link
      return "" if READ_ONLY_RESOURCES.include?(controller_name)
      link_to "Edit", {:controller => controller_name, :action => 'edit', :id => params[:id] }, :class => 'edit'
    end

    def generate_back_link
      link_to "Back", {:controller => controller_name, :action => 'index'}, :class => 'back'
    end

    def generate_destroy_link
      return "" if READ_ONLY_RESOURCES.include?(controller_name) or DESTROY_BLOCKED_RESOURCES.include?(controller_name)
      link_to "Destroy", @record, {:confirm => "Are you sure you want to destroy this #{model_name}?", :method => :delete, :class => 'destroy'}
    end

    def include_actions_in_table?
      current_page?(:controller => 'applications', :action => 'index') or
        current_page?(:controller => 'jobs', :action => 'index')
    end

  end

end
