module Naf
  module ApplicationHelper

    DESTROY_BLOCKED_RESOURCES = ["jobs"]
    READ_ONLY_RESOURCES = ["application_types", "application_run_group_restrictions"]
    CREATE_BLOCKED_RESOURCES = []
    ALL_RESOURCES = [ "jobs",  "applications", "application_schedules",
                      "machines", "affinities", "affinity_classifications", 
                      "application_run_group_restrictions", "application_types"]

    def tabs
      ALL_RESOURCES
    end

    def highlight_tab?(tab)
      case tab
      when "machines"
        [tab, "machine_affinity_slots"].include?(controller_name)
      when "jobs"
        [tab, "job_affinity_tabs"].include?(controller_name)
      when "application_schedules"
        [tab, "application_schedule_affinity_tabs"].include?(controller_name)
      else
        tab == controller_name
      end
    end

    def parent_resource_link
      case controller_name
      when "job_affinity_tabs"
        link_to "Back to Job", :controller => 'jobs', :action => 'show', :id => params[:job_id]
      when "application_schedule_affinity_tabs"
        link_to "Back to Application Schedule", :controller => 'application_schedules', :action => 'show', :id => params[:application_schedule_id]
      when "machine_affinity_slots"
        link_to "Back to Machine", :controller => 'machines', :action => 'show', :id => params[:machine_id]
      else 
        ""
      end
    end

    def nested_resource_index?
      ["job_affinity_tabs", "application_schedule_affinity_tabs", "machine_affinity_slots"].include?(controller_name) and !params[:id]
    end

    def table_title
      current_page?(naf.root_url) ? "Jobs" : make_header(controller_name)
    end

    def generate_affinity_tabs_link
      case controller_name
      when "jobs"
        link_to "Job Affinity Tabs", :controller => 'job_affinity_tabs', :action => 'index', :job_id => params[:id]
      when "application_schedules"
        link_to "Application Schedule Affinity Tabs", :controller => 'application_schedule_affinity_tabs', :action => 'index', :application_schedule_id => params[:id]
      when "machines"
        link_to "Machine Affinity Slots", :controller => 'machine_affinity_slots', :action => 'index', :machine_id => params[:id]
      else
        ""
      end
    end

    def generate_index_link(name)
      link_to name.split('_').map(&:capitalize).join(' '), {:controller => name, :action => 'index'}
    end

    def generate_create_link
      return "" if READ_ONLY_RESOURCES.include?(controller_name) or CREATE_BLOCKED_RESOURCES.include?(controller_name)
      return link_to "Add a Job", "#", {:class => 'add_job'} if display_job_search_link?
      link_to "Create new #{model_name}", {:controller => controller_name, :action => 'new'}
    end

    def display_job_search_link?
      current_page?(naf.root_url) or current_page?(:controller => 'jobs', :action => 'index')
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
      link_to "Back to #{make_header(controller_name)}", {:controller => controller_name, :action => 'index'}, :class => 'back'
    end

    def generate_destroy_link
      return "" if READ_ONLY_RESOURCES.include?(controller_name) or DESTROY_BLOCKED_RESOURCES.include?(controller_name)
      case controller_name
      when "job_affinity_tabs"
        link_to "Destroy", job_job_affinity_tab_url(@job, @record), {:confirm => "Are you sure you want to destroy this #{model_name}?", :method => :delete, :class => 'destroy'}
      when "application_schedule_affinity_tabs"
        link_to "Destroy", application_schedule_application_schedule_affinity_tab_url(@application_schedule, @record), {:confirm => "Are you sure you want to destroy this #{model_name}?", :method => :delete, :class => 'destroy'}
      when "machine_affinity_slots"
        link_to "Destroy", machine_machine_affinity_slot_url(@machine, @record), {:confirm => "Are you sure you want to destroy this #{model_name}?", :method => :delete, :class => 'destroy'}
      else
        link_to "Destroy", @record, {:confirm => "Are you sure you want to destroy this #{model_name}?", :method => :delete, :class => 'destroy'}
      end
    end

    def include_actions_in_table?
      current_page?(naf.root_url) or
      current_page?(:controller => 'applications', :action => 'index') or
        current_page?(:controller => 'jobs', :action => 'index') 
    end

  end

end
