class MattermostSetting < ActiveRecord::Base
  has_many :projects_settings, class_name: 'ProjectsMattermostSetting', dependent: :destroy

  enum kind: [:outcoming_hook_url, :event, :incoming_hook_setting]
end
