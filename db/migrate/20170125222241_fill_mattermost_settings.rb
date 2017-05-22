class FillMattermostSettings < ActiveRecord::Migration
  def up
    settings = {
      'hook_url_default' => {
        kind: :outcoming_hook_url,
        title: 'Default hook url'
      },
      'hook_url_secondary' => {
        kind: :outcoming_hook_url,
        title: 'Secondary hook url'
      },
      'work_package_is_added' => {
        kind: :event,
        title: 'Track new work package adding'
      },
      'work_package_status_is_changed' => {
        kind: :event,
        title: 'Track status changing'
      },
      'work_package_assignee_is_changed' => {
        kind: :event,
        title: 'Track assignee changing'
      },
      'journal_notes_is_changed' => {
        kind: :event,
        title: 'Track new message adding/changing'
      }
    }

    settings.each do |key, value|
      MattermostSetting.find_or_create_by(name: key).tap do |s|
        s.kind = MattermostSetting.kinds[value[:kind]]
        s.title = value[:title]
        s.value_is_editable = ( value[:kind] == :outcoming_hook_url )
        s.save
      end
    end

    Project.all.each do |project|
      MattermostSetting.all.each do |setting|
        project.mattermost_settings.find_or_create_by(setting: setting).tap do |s|
          s.value = project.mattermost_hook_url if setting.name == 'hook_url_default'
          s.enabled = true
          s.save
        end
      end
    end
  end

  def down
  end
end
