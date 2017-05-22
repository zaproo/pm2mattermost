class AddMattermostUsers < ActiveRecord::Migration
  def change
    create_table :mattermost_users do |t|
      t.belongs_to :user
      t.string :name

      t.timestamps null: false

      t.index [:user_id], unique: true
    end
  end
end
