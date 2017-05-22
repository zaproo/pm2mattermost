class RemoveMattermostHookUrlFromProject < ActiveRecord::Migration
  def up
    remove_column :projects, :mattermost_hook_url, :string
  end

  def down
  end
end
