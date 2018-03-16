class JiraIssue < ApplicationRecord

  validates :key, presence: true
  validates :summary, presence: true
  validates :status_name, presence: true

  belongs_to :reporter, class_name: 'Employee'
  belongs_to :project, class_name: 'JiraProject'
  belongs_to :assignee, class_name: 'Employee', optional: true
end
