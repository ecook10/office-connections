class AddIssueOpenedAtField < ActiveRecord::Migration[5.1]
  def change
    add_column :jira_issues, :opened_at, :datetime
  end
end
