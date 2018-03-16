class CreateInitialTables < ActiveRecord::Migration[5.1]
  def change
    create_table :employees do |t|
      t.timestamps
      t.string :jira_key, null: false
      t.string :name, null: false
    end
    create_table :jira_projects do |t|
      t.timestamps
      t.string :key, null: false
      t.string :name, null: false
    end
  end
end
