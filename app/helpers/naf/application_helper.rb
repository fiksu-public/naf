module Naf
  module ApplicationHelper
    include ActionView::Helpers::TextHelper

    NAF_DESTROY_BLOCKED_RESOURCES = ["jobs", "applications", "machines", "job_affinity_tabs", "janitorial_assignments"]
    NAF_READ_ONLY_RESOURCES = []
    NAF_CREATE_BLOCKED_RESOURCES = []
    NAF_ALL_VISIBLE_RESOURCES = {
                              "jobs" => "",
                              "applications" => "",
                              "machines" => "",
                              "affinities" => "",
                              "loggers" => ["logger_styles", "logger_names"],
                              "janitorial_assignments" => ["janitorial_archive_assignments", "janitorial_create_assignments", "janitorial_drop_assignments"]
                            }

    def naf_tabs
      NAF_ALL_VISIBLE_RESOURCES
    end

    def naf_last_queued_at_link(app)
      if job = app.last_queued_job
        link_to "#{time_ago_in_words(job.created_at, true)} ago", naf.job_path(job)
      else
        ""
      end
    end

    def naf_highlight_tab?(tab)
      case tab
        when "machines"
          [tab, "machine_affinity_slots"].include?(controller_name)
        when "jobs"
          [tab, "job_affinity_tabs"].include?(controller_name)
        when "applications"
          [tab, "application_schedule_affinity_tabs"].include?(controller_name)
        when "loggers"
          ["logger_styles", "logger_names"].include?(controller_name)
        when "janitorial_assignments"
          ["Naf::JanitorialArchiveAssignment", "Naf::JanitorialCreateAssignment", "Naf::JanitorialDropAssignment"].include?(params[:type])
        when "janitorial_archive_assignments"
          "Naf::JanitorialArchiveAssignment" == params[:type]
        when "janitorial_create_assignments"
          "Naf::JanitorialCreateAssignment" == params[:type]
        when "janitorial_drop_assignments"
          "Naf::JanitorialDropAssignment" == params[:type]
        else
          tab == controller_name
      end
    end

    def naf_parent_resource_link
      case controller_name
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

    def naf_nested_resource_index?
      ["job_affinity_tabs", "application_schedule_affinity_tabs", "machine_affinity_slots"].include?(controller_name) and !params[:id]
    end

    def naf_table_title
      if current_page?(naf.janitorial_archive_assignments_path)
        "Janitorial Archive Assignment"
      elsif current_page?(naf.janitorial_create_assignments_path)
        "Janitorial Create Assignment"
      elsif current_page?(naf.janitorial_drop_assignments_path)
        "Janitorial Drop Assignment"
      else
        case controller_name
          when "application_schedule_affinity_tabs"
            Application.find(params[:application_id]).title + ", Affinity Tabs"
          when "machine_affinity_slots"
            machine = Machine.find(params[:machine_id])
            name = machine.server_name
            ((name and name.length > 0) ? name : machine.server_address) + ", Affinity Slots"
          else
            naf_make_header(controller_name)
        end
      end
    end

    def naf_generate_child_resources_link
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

    def naf_generate_index_link(name)
      case name
        when "loggers"
          link_to "Loggers", naf.logger_styles_path
        when "janitorial_assignments"
          link_to "Janitorial Assignments", naf.janitorial_archive_assignments_path
        when "janitorial_archive_assignments"
          link_to "Janitorial Archive Assignments", naf.janitorial_archive_assignments_path
        when "janitorial_create_assignments"
          link_to "Janitorial Create Assignments", naf.janitorial_create_assignments_path
        when "janitorial_drop_assignments"
          link_to "Janitorial Drop Assignments", naf.janitorial_drop_assignments_path
        else
          link_to name.split('_').map(&:capitalize).join(' '), {:controller => name, :action => 'index'}
      end
    end

    def naf_generate_create_link
      return "" if NAF_READ_ONLY_RESOURCES.include?(controller_name) or NAF_CREATE_BLOCKED_RESOURCES.include?(controller_name)
      return link_to "Add a Job", naf.new_job_path, {:class => 'add_job'} if naf_display_job_search_link?
      link_to "Create new #{naf_model_name}", {:controller => controller_name, :action => 'new'}
    end

    def naf_display_job_search_link?
      current_page?(naf.root_url) or current_page?(:controller => 'jobs', :action => 'index')
    end

    def naf_model_name
      name_pieces = controller_name.split('_')
      name_pieces[name_pieces.size - 1] = name_pieces.last.singularize
      name_pieces.map(&:capitalize).join(' ')
    end

    def naf_make_header(attribute)
      attribute.to_s.split('_').map(&:capitalize).join(' ')
    end

    def naf_generate_edit_link
      return "" if NAF_READ_ONLY_RESOURCES.include?(controller_name)
      link_to "Edit", {:controller => controller_name, :action => 'edit', :id => params[:id] }, :class => 'edit'
    end

    def naf_generate_back_link
      link_to "Back to #{naf_make_header(controller_name)}", {:controller => controller_name, :action => 'index'}, :class => 'back'
    end

    def naf_generate_destroy_link
      return "" if NAF_READ_ONLY_RESOURCES.include?(controller_name) or NAF_DESTROY_BLOCKED_RESOURCES.include?(controller_name)
      case controller_name
        when "application_schedule_affinity_tabs"
          link_to "Destroy", application_application_schedule_application_schedule_affinity_tab_url(@application, @application_schedule, @record), {:confirm => "Are you sure you want to destroy this #{naf_model_name}?", :method => :delete, :class => 'destroy'}
        when "machine_affinity_slots"
          link_to "Destroy", machine_machine_affinity_slot_url(@machine, @record), {:confirm => "Are you sure you want to destroy this #{naf_model_name}?", :method => :delete, :class => 'destroy'}
        else
          link_to "Destroy", @record, {:confirm => "Are you sure you want to destroy this #{naf_model_name}?", :method => :delete, :class => 'destroy'}
      end
    end

    def naf_papertrail_link(record, runner = false)
      if group_id = Naf.papertrail_group_id
        url = "http://www.papertrailapp.com/groups/#{group_id}/events"
        if record.kind_of?(::Naf::Job) || record.kind_of?(::Logical::Naf::Job)
          if record.pid.present?
            query = "jid(#{record.id})"
            url << "?q=#{CGI.escape(query)}"
          end
        elsif record.kind_of?(::Naf::Machine) || record.kind_of?(::Logical::Naf::Machine)
            query = record.server_name
            unless query.nil?
              query << " runner" if runner
              url << "?q=#{CGI.escape(query)}"
            end
        end
      else
        url = "http://www.papertrailapp.com/dashboard"
      end
      return url
    end

    def link_to_remove_fields(name, f)
      f.hidden_field(:_destroy) + link_to_function(name, "remove_fields(this)")
    end

    def link_to_add_fields(name, f, association)
      new_object = f.object.class.reflect_on_association(association).klass.new
      fields = f.fields_for(association, new_object, :child_index => "new_#{association}") do |builder|
        render(association.to_s, :f => builder)
      end
      link_to_function(name, "add_fields(this, \"#{association}\", \"#{escape_javascript(fields)}\")", :id => 'add_prerequisite')
    end

  end
end
