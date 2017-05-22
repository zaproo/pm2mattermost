require_dependency 'journal'

module OpenProject::Mattermost::Patches::JournalPatch
  def self.included(base)
    base.class_eval do
      include InstanceMethods

      has_one :mattermost_event

      after_save :mattermost_event_notification, if: :notes_changed?
    end
  end

  module InstanceMethods
    def mattermost_event_notification
      Redmine::Hook.call_hook(
        :mattermost_event_notification,
        { journal: self }
      ) if notes.present?
      true
    end
  end
end

Journal.send(:include, OpenProject::Mattermost::Patches::JournalPatch)
