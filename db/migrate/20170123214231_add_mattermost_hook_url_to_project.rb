class AddMattermostHookUrlToProject < ActiveRecord::Migration
  def up
    add_column :projects, :mattermost_hook_url, :string
  end

  def down
  end
end
