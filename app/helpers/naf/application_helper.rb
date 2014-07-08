module Naf

  ActionView::Base.field_error_proc = Proc.new do |html_tag, instance|
    errors = Array(instance.error_message).join('; ')
    if html_tag =~ /^<label for=/
      %(<span class="validation-error">#{html_tag}</span>).html_safe
    else
      %(#{html_tag}<span class="validation-error">&nbsp;#{errors}</span>).html_safe
    end
  end

  module ApplicationHelper
    include ActionView::Helpers::TextHelper

    NAF_DESTROY_BLOCKED_RESOURCES = ["historical_jobs",
                                     "applications",
                                     "machines",
                                     "historical_job_affinity_tabs",
                                     "janitorial_assignments"]
    NAF_READ_ONLY_RESOURCES = []
    NAF_CREATE_BLOCKED_RESOURCES = []
    NAF_ALL_VISIBLE_RESOURCES = {
                                  'historical_jobs' => '',
                                  'scripts' => ['applications',
                                                'application_schedules'],
                                  'machines' => '',
                                  'runners' => ['machine_runners',
                                                'machine_runner_invocations'],
                                  'affinities' => '',
                                  'loggers' => ['logger_styles', 'logger_names'],
                                  'janitorial_assignments' => ['janitorial_archive_assignments',
                                                               'janitorial_create_assignments',
                                                               'janitorial_drop_assignments'],
                                  'status' => ''
                                }

    def naf_tabs
      NAF_ALL_VISIBLE_RESOURCES
    end

    def naf_last_queued_at_link(app)
      if historical_job = app.last_queued_job
        link_to "#{time_ago_in_words(historical_job.created_at, true)} ago, " +
          "#{historical_job.created_at.localtime.strftime("%Y-%m-%d %r")}",
          naf.historical_job_path(historical_job)
      else
        ""
      end
    end

    def naf_highlight_tab?(tab)
      case tab
        when "machines"
          [tab,
           "machine_affinity_slots"].include?(controller_name)
        when "runners"
          ["machine_runners",
           "machine_runner_invocations"].include?(controller_name)
        when "historical_jobs"
          [tab,
           "historical_job_affinity_tabs"].include?(controller_name)
        when "scripts"
          [tab,
           "applications",
           "application_schedules",
           "application_schedule_affinity_tabs"].include?(controller_name)
        when "loggers"
          ["logger_styles",
           "logger_names"].include?(controller_name)
        when "janitorial_assignments"
          ["Naf::JanitorialArchiveAssignment",
           "Naf::JanitorialCreateAssignment",
           "Naf::JanitorialDropAssignment"].include?(params[:type])
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
        when "historical_job_affinity_tabs"
          link_to "Back to Historical Job",
            controller: 'historical_jobs',
            action: 'show',
            id: params[:historical_job_id]
        when "application_schedule_affinity_tabs"
          link_to "Back to Application Schedule",
            controller: 'application_schedules',
            action: 'show',
            id: params[:application_schedule_id]
        when "machine_affinity_slots"
          link_to "Back to Machine",
            controller: 'machines',
            action: 'show',
            id: params[:machine_id]
        else
          ""
      end
    end

    def naf_nested_resource_index?
      ["historical_job_affinity_tabs",
       "application_schedule_affinity_tabs",
       "machine_affinity_slots",
       "application_schedules"].include?(controller_name) and !params[:id]
    end

    def naf_table_title
      if current_page?(naf.janitorial_archive_assignments_path)
        "Janitorial Archive Assignment"
      elsif current_page?(naf.janitorial_create_assignments_path)
        "Janitorial Create Assignment"
      elsif current_page?(naf.janitorial_drop_assignments_path)
        "Janitorial Drop Assignment"
      elsif current_page?(main_app.naf_path)
        "Jobs"
      else
        case controller_name
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
        when "historical_jobs"
          link_to "Historical Job Affinity Tabs",
            controller: 'historical_job_affinity_tabs',
            action: 'index',
            historical_job_id: params[:id]
        when "applications"
          if @record.application_schedule
            link_to "Application Schedule Affinity Tabs",
              controller: 'application_schedule_affinity_tabs',
              action: 'index',
              application_schedule_id: @record.application_schedule.id,
              application_id: @record.id
          else
            ""
          end
        when "machines"
          link_to "Machine Affinity Slots",
            controller: 'machine_affinity_slots',
            action: 'index',
            machine_id: params[:id]
        else
          ""
      end
    end

    def naf_generate_index_link(name)
      case name
        when "historical_jobs"
          link_to "Jobs", main_app.naf_path
        when "loggers"
          link_to "Loggers", naf.logger_styles_path
        when "runners"
          link_to "Runners", naf.machine_runners_path
        when "scripts"
          link_to "Applications", naf.applications_path
        when "janitorial_assignments"
          link_to "Janitorial Assignments", naf.janitorial_archive_assignments_path
        when "janitorial_archive_assignments"
          link_to "Janitorial Archive Assignments", naf.janitorial_archive_assignments_path
        when "janitorial_create_assignments"
          link_to "Janitorial Create Assignments", naf.janitorial_create_assignments_path
        when "janitorial_drop_assignments"
          link_to "Janitorial Drop Assignments", naf.janitorial_drop_assignments_path
        else
          link_to name.split('_').map(&:capitalize).join(' '), { controller: name, action: 'index'}
      end
    end

    def naf_generate_create_link
      return '' if NAF_READ_ONLY_RESOURCES.include?(controller_name) ||
        NAF_CREATE_BLOCKED_RESOURCES.include?(controller_name)

      return link_to "Add a Job",
        naf.new_historical_job_path,
        { class: 'add_job' } if naf_display_job_search_link?

      return link_to "Create new #{naf_model_name}", { controller: controller_name, action: 'new' }
    end

    def naf_display_job_search_link?
      current_page?(naf.root_url) or current_page?(controller: 'historical_jobs', action: 'index')
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
      link_to "Edit",
        { controller: controller_name, action: 'edit', id: params[:id] },
        class: 'edit'
    end

    def naf_generate_back_link
      link_to "Back to #{naf_make_header(controller_name)}",
        { controller: controller_name, action: 'index' },
        class: 'back'
    end

    def naf_generate_destroy_link
      return '' if NAF_READ_ONLY_RESOURCES.include?(controller_name) ||
        NAF_DESTROY_BLOCKED_RESOURCES.include?(controller_name)

      case controller_name
        when "application_schedule_affinity_tabs"
          link_to "Destroy",
            application_schedule_application_schedule_affinity_tab_url(@application_schedule, @record),
            { confirm: "Are you sure you want to destroy this #{naf_model_name}?",
              method: :delete,
              class: 'destroy' }
        when "machine_affinity_slots"
          link_to "Destroy", machine_machine_affinity_slot_url(@machine, @record),
            { confirm: "Are you sure you want to destroy this #{naf_model_name}?",
              method: :delete,
              class: 'destroy' }
        else
          link_to "Destroy", @record,
            { confirm: "Are you sure you want to destroy this #{naf_model_name}?",
              method: :delete,
              class: 'destroy' }
      end
    end

    def naf_link_to_remove_fields(name, f)
      f.hidden_field(:_destroy) + link_to_function(name, "remove_fields(this)")
    end

    def naf_link_to_add_fields(name, f, association)
      new_object = f.object.class.reflect_on_association(association).klass.new
      fields = f.fields_for(association, new_object, child_index: "new_#{association}") do |builder|
        render(association.to_s, f: builder)
      end
      link_to_function(
        name,
        "add_fields(this, \"#{association}\", \"#{escape_javascript(fields)}\")", id: 'add_prerequisite'
      )
    end

    def add_color(status)
      if status == 'Running'
        'running'
      elsif status == 'Queued' || status == 'Waiting'
        'queued'
      elsif status =~ /Terminat/ || status == 'Error' || status == 'Failed to Start'
        'dead'
      end
    end

    def http_protocol
      if ['staging', 'production'].include?(Rails.env)
        'https://'
      else
        'http://'
      end
    end

  end
end
