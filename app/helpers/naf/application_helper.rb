module Naf
  module ApplicationHelper
    include ActionView::Helpers::TextHelper

    DESTROY_BLOCKED_RESOURCES = ["jobs"]
    READ_ONLY_RESOURCES = ["application_types", "application_run_group_restrictions"]
    CREATE_BLOCKED_RESOURCES = []
    ALL_VISIBLE_RESOURCES = [ "jobs",  "applications", "machines", "affinities"]

    def tabs
      ALL_VISIBLE_RESOURCES
    end

    def last_queued_at_link(app)
      if job = app.last_queued_job
        link_to "#{time_ago_in_words(job.created_at, true)} ago", job_path(job)
      else
        ""
      end
    end
    
    def format_index_table_row(row, col)
      value = row.send(col)
      if value.is_a?(String)
        return truncate(value)
      else
        return value
      end
    end

    def application_url(app)
      url_for({:controller => 'applications', :action => 'show', :id => app.id})
    end

    def schedule_url(schedule)
      url_for({:controller => 'application_schedules', :action => 'show', :application_id => schedule.application_id, :id => schedule.id})
    end

    def generate_schedule_link(app)
      schedule_button = image_tag('clock.png', :class => 'action', :title => 'Schedule')
      if schedule = app.application_schedule
        link_to schedule_button, {:controller => 'application_schedules', :action => 'show', :application_id => app.id, :id => schedule.id}
      else
        link_to schedule_button, {:controller => 'application_schedules', :action => 'new', :application_id => app.id}
      end
    end

    def highlight_tab?(tab)
      case tab
      when "machines"
        [tab, "machine_affinity_slots"].include?(controller_name)
      when "jobs"
        [tab, "job_affinity_tabs"].include?(controller_name)
      when "applications"
        [tab, "application_schedules", "application_schedule_affinity_tabs"].include?(controller_name)
      else
        tab == controller_name
      end
    end

    def parent_resource_link
      case controller_name
      when "application_schedules"
        link_to "Back to Application", :controller => 'applications', :action => 'show', :id => params[:application_id]
      when "job_affinity_tabs"
        link_to "Back to Job", :controller => 'jobs', :action => 'show', :id => params[:job_id]
      when "application_schedule_affinity_tabs"
        link_to "Back to Application", :controller => 'applications', :action => 'show', :id => params[:application_id]
      when "machine_affinity_slots"
        link_to "Back to Machine", :controller => 'machines', :action => 'show', :id => params[:machine_id]
      else 
        ""
      end
    end

    def nested_resource_index?
      ["job_affinity_tabs", "application_schedule_affinity_tabs", "machine_affinity_slots", "application_schedules"].include?(controller_name) and !params[:id]
    end

    def table_title
      if current_page?(naf.root_url)
        "Jobs"
      else 
        case controller_name
        when "application_schedule_affinity_tabs"
          Application.find(params[:application_id]).title + ", Affinity Tabs"
        when "machine_affinity_slots"
          machine = Machine.find(params[:machine_id])
          name = machine.server_name
          ((name and name.length > 0) ? name : machine.server_address) + ", Affinity Slots"
        else
          make_header(controller_name)
        end
      end
    end

    def generate_child_resources_link
      case controller_name
      when "jobs"
        link_to "Job Affinity Tabs", :controller => 'job_affinity_tabs', :action => 'index', :job_id => params[:id]
      when "applications"
        if @record.application_schedule
          link_to "Application Schedule Affinity Tabs", :controller => 'application_schedule_affinity_tabs', :action => 'index', :application_schedule_id => @record.application_schedule.id, :application_id => @record.id
        else
          ""
        end
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
      case controller_name.to_sym
      when :application_schedule_affinity_tabs
        link_to "Back to Application", {:controller => 'applications', :action => 'show', :id => @record.application.id}, :class => 'back'
      else
        link_to "Back to #{make_header(controller_name)}", {:controller => controller_name, :action => 'index'}, :class => 'back'
      end
    end

    def generate_destroy_link
      return "" if READ_ONLY_RESOURCES.include?(controller_name) or DESTROY_BLOCKED_RESOURCES.include?(controller_name)
      case controller_name
      when "job_affinity_tabs"
        link_to "Destroy", job_job_affinity_tab_url(@job, @record), {:confirm => "Are you sure you want to destroy this #{model_name}?", :method => :delete, :class => 'destroy'}
      when "application_schedule_affinity_tabs"
        link_to "Destroy", application_application_schedule_application_schedule_affinity_tab_url(@application, @application_schedule, @record), {:confirm => "Are you sure you want to destroy this #{model_name}?", :method => :delete, :class => 'destroy'}
      when "machine_affinity_slots"
        link_to "Destroy", machine_machine_affinity_slot_url(@machine, @record), {:confirm => "Are you sure you want to destroy this #{model_name}?", :method => :delete, :class => 'destroy'}
      when "application_schedules"
        link_to "Destroy", schedule_url(@record), {:confirm => "Are you sure you want to destroy this #{model_name}?", :method => :delete, :class => 'destroy'}
      when "applications"
        link_to "Destroy", @record.app, {:confirm => "Are you sure you want to destroy this application?", :method => :delete, :class => 'destroy'}
      else
        link_to "Destroy", @record, {:confirm => "Are you sure you want to destroy this #{model_name}?", :method => :delete, :class => 'destroy'}
      end
    end

    def include_actions_in_table?
      current_page?(naf.root_url) or
      current_page?(:controller => 'applications', :action => 'index') or
        current_page?(:controller => 'jobs', :action => 'index') 
    end

    def papertrail_link(job)
      if group_id = Naf.papertrail_group_id
        url = "http://www.papertrailapp.com/groups/#{group_id}/events"
        if job.pid.present?
          query = "jid(#{job.id})"
          url << "?q=#{CGI.escape(query)}"
        end
      else
        url = "http://www.papertrailapp.com/dashboard"
      end
      return url
    end
  end

end
