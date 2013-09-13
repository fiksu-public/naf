module Process::Naf
  class Application
    module Component
      def self.included(base)
        base.send(:include, ::Af::Application::Component)
        base.extend(ClassMethods)
      end

      module ClassMethods
        # XXX not used yet
      end

      def fetch_naf_job
        return af_application.try(:fetch_naf_job)
      end

      def update_job_status
        return af_application.try(:update_job_status)
      end

      def job_tag_block(*tags, &block)
        return af_application.try(:job_tag_block, *tags, &block)
      end

      def update_job_tags(old_tags, new_tags)
        return af_application.try(:update_job_tags, old_tags, new_tags)
      end

      def add_job_tags(*new_tags)
        return af_application.try(:add_job_tags, *new_tags)
      end

      def remove_job_tags(*old_tags)
        return af_application.try(:remove_job_tags, *old_tags)
      end
    end
  end
end
