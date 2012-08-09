
module Naf
  module ApplicationHelper
    
    def tabs
      [ "applications", "application_types", "application_schedules", "application_schedule_affinity_tabs", "machines", "machine_affinity_slots",
              "affinities", "affinity_classifications","application_run_groups", "application_run_group_restrictions"]
    end

    def generate_index_link(name)
      link_to name.split('_').map(&:capitalize).join(' '), {:controller => name, :action => 'index'}
    end

    def generate_create_link
      return "" if controller_name == "application_types"
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
      link_to "Edit", {:controller => controller_name, :action => 'edit', :id => params[:id] }
    end

  end

end
