require_dependency 'user'

module OpenProject::Mattermost::Patches::UserPatch
  def self.included(base)
    base.class_eval do
      has_one :mattermost_user
    end
  end
end

Project.send(:include, OpenProject::Mattermost::Patches::UserPatch)
