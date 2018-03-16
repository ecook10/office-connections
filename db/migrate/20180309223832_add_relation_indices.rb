class AddRelationIndices < ActiveRecord::Migration[5.1]
  def change
    add_index :jira_issues, :reporter_id
    add_index :jira_issues, :project_id
    add_index :jira_issues, :assignee_id
  end
end
