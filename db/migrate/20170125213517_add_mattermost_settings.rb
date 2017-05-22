class AddMattermostSettings < ActiveRecord::Migration
  def change
    create_table :mattermost_settings do |t|
      t.integer :kind
      t.string :name
      t.text :title
      t.boolean :value_is_editable

      t.timestamps null: false
    end

    create_table :projects_mattermost_settings do |t|
      t.text :value
      t.boolean :enabled

      t.belongs_to :project
      t.belongs_to :mattermost_setting

      t.timestamps null: false

      t.index [:project_id, :mattermost_setting_id], unique: true, name: 'index_on_project_id_and_mattermost_setting_id'
    end
  end
end
