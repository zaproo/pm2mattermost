class MoveTokenToCommonSettings < ActiveRecord::Migration
  def up
    incoming_hooks_tokens = ProjectsMattermostSetting.joins(:setting)
      .where(mattermost_settings: {name: 'incoming_hook_token'})
      .where(enabled: true)
      .distinct
      .map(&:value)
      .join(' ')

    Setting["plugin_openproject_mattermost"] = {
      "mattermost_incoming_hooks_tokens" => incoming_hooks_tokens
    }

    MattermostSetting.where(kind: :incoming_hook_setting).destroy_all
  end

  def down
  end
end
