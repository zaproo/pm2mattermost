class ProjectsMattermostSetting < ActiveRecord::Base
  belongs_to :project
  belongs_to :setting, class_name: 'MattermostSetting', foreign_key: :mattermost_setting_id

  validates_presence_of :project
  validates_presence_of :setting
end
