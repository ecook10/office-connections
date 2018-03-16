class JiraProject < ApplicationRecord

  validates :key, presence: true
  validates :name, presence: true
  
  has_many :issues, class_name: 'JiraIssue', foreign_key: 'project_id'

  has_many :assignees, -> { distinct }, through: :issues, source: :assignee
  has_many :reporters, -> { distinct }, through: :issues, source: :reporter

  '''
  Proportion of all issues opened on this project that are assigned to the given employee
  '''
  def assignee_proportion(assignee:)
    self.issues.where(assignee: assignee).count.to_f / 
    self.issues.count
  end

  '''
  Proportion of all issues opened on this project that are assigned to the given employee
  '''
  def reporter_proportion(reporter:)
    self.issues.where(reporter: reporter).count.to_f / 
    self.issues.count
  end
end
