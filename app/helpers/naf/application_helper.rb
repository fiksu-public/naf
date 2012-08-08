module Naf
  module ApplicationHelper
    
    def tabs
      [ "applications", "application_schedules", "application_schedule_affinity_tabs", "machines", "machine_affinity_slots",
              "affinities", "affinity_classifications","application_run_groups", "application_run_group_restrictions"]
    end

    def generate_index_link(name)
      link_to name.split('_').map(&:capitalize).join(' '), {:controller => name, :action => 'index'}
    end

    def generate_create_link
      name_pieces = controller_name.split('_')
      name_pieces[name_pieces.size - 1] = name_pieces.last.singularize
      link_text = "Create New " << name_pieces.map(&:capitalize).join(' ')
      link_to link_text, {:controller => controller_name, :action => 'new'}
    end

  end

end
