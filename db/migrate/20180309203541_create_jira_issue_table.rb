class CreateJiraIssueTable < ActiveRecord::Migration[5.1]
  def change
    create_table :jira_issues do |t|
      t.timestamps
      t.string :key, null: false
      t.string :summary, null: false
      t.string :status_name, null: false
      t.integer :reporter_id, null: false
      t.integer :project_id, null: false
      t.integer :assignee_id
    end
  end
end
