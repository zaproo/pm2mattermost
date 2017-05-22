class FillIncomingHooksSettings < ActiveRecord::Migration
  def up

    # fill in incoming hooks settings

    settings = {
      'incoming_hook_token' => 'Token',
      'incoming_hook_channel_name' => 'Channel name'
    }

    settings.each do |key, value|
      MattermostSetting.find_or_create_by(name: key).tap do |s|
        s.kind = MattermostSetting.kinds[:incoming_hook_setting]
        s.title = value
        s.value_is_editable = true
        s.save
      end
    end

    Project.all.each do |project|
      MattermostSetting.where(kind: :incoming_hook_setting).each do |setting|
        project.mattermost_settings.find_or_create_by(setting: setting)
      end
    end

    #rename outcoming hooks settings

    setting = MattermostSetting.where(name: 'hook_url_default').first
    setting.update_attributes(name: 'outcoming_hook_url_default') if setting

    setting = MattermostSetting.where(name: 'hook_url_secondary').first
    setting.update_attributes(name: 'outcoming_hook_url_secondary') if setting
  end

  def down
  end
end
