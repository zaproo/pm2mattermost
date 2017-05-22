class MattermostSettingsController < ApplicationController
  # this is necessary if you want the project menu in the sidebar for your view
  before_filter :find_optional_project, only: [:get_data, :update_data]

  def get_data
    @data = {}
    @data['outcoming_hooks'] = MattermostSetting.where
      .not(kind: :incoming_hook_setting)
      .map { |setting| find_setting(setting) }
    render 'mattermost_settings/form'
  end

  def update_data
    update_settings
    flash[:notice] = l(:mattermost_setting_updated_successfully)
    redirect_to action: :get_data, project_id: @project.id
  end

  def update_common_data
    Setting["plugin_openproject_mattermost"] = params[:settings].permit!.to_h
    update_mattermost_users
    flash[:notice] = l(:notice_successful_update)
    redirect_to "/settings/plugin/openproject_mattermost"
  end

  private

  def update_settings
    params[:data].map do |name, item|
      setting = MattermostSetting.find_by(name: name)
      next unless setting.present?
      @project.mattermost_settings.find_or_create_by(setting: setting).tap do |s|
        s.value = item[:value].try(:strip)
        s.enabled = item[:enabled]
        s.save
      end
    end
  end

  def update_mattermost_users
    params[:mattermost_users].map do |login, mattermost_user|
      user = User.find_by(login: login)
      next unless user.present?
      MattermostUser.find_or_create_by(user: user).tap do |s|
        s.name = mattermost_user[:name].try(:strip)
        s.save
      end
    end
  end

  def find_setting(setting)
    setting.projects_settings.where(project: @project).first ||
    setting.projects_settings.new(project: @project, enabled: false)
  end
end
