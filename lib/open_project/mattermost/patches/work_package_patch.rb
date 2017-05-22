require_dependency 'work_package'

module OpenProject::Mattermost::Patches::WorkPackagePatch
  def self.included(base)
    base.class_eval do
      include InstanceMethods

      before_save :new_record_check
      after_save :mattermost_event_notification
    end
  end

  module InstanceMethods
    def new_record_check
      @is_new_record = new_record?
      true
    end

    def mattermost_event_notification
      if current_journal.present? && (@is_new_record || status_id_changed? || assigned_to_id_changed?)
        Redmine::Hook.call_hook(
          :mattermost_event_notification,
          { journal: self.current_journal }
        )
      end
      true
    end
  end
end

WorkPackage.send(:include, OpenProject::Mattermost::Patches::WorkPackagePatch)
