require_dependency 'project'

module OpenProject::Mattermost::Patches::ProjectPatch
  def self.included(base)
    base.class_eval do
      include InstanceMethods

      has_many :mattermost_settings, class_name: 'ProjectsMattermostSetting', dependent: :destroy
    end
  end

  module InstanceMethods
    def mattermost_setting_enabled?(name)
      mattermost_settings
        .joins(:setting)
        .where(enabled: true, mattermost_settings: { name: name })
        .present?
    end

    def mattermost_setting_for(name)
      mattermost_settings
        .joins(:setting)
        .where(enabled: true, mattermost_settings: { name: name })
        .first
        .try(:value)
    end
  end
end

Project.send(:include, OpenProject::Mattermost::Patches::ProjectPatch)
