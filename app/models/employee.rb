class Employee < ApplicationRecord

  validates :jira_key, presence: true
  validates :name, presence: true

  has_many :assigned_jira_issues, class_name: 'JiraIssue', foreign_key: 'assignee_id'

  has_many :assigned_jira_projects, -> { distinct }, through: :assigned_jira_issues, source: :project
  has_many :related_assignment_issues, through: :assigned_jira_projects, source: :issues
  has_many :coassignees, -> { distinct }, through: :related_assignment_issues, source: :assignee
  has_many :assigned_reporters, -> { distinct }, through: :related_assignment_issues, source: :reporter

  has_many :reported_jira_issues, class_name: 'JiraIssue', foreign_key: 'reporter_id'

  has_many :reported_jira_projects, -> { distinct }, through: :reported_jira_issues, source: :project
  has_many :related_reporting_issues, through: :reported_jira_projects, source: :issues
  has_many :coreporters, -> { distinct }, through: :related_reporting_issues, source: :reporter
  has_many :reporting_assignees, -> { distinct }, through: :related_reporting_issues, source: :assignee


  def jira_issues_assigned_between(start_time:, end_time:)
    JiraIssue.where(assignee_id: self.id).where("opened_at BETWEEN ? AND ?", start_time, end_time)
  end

  def jira_projects_assigned_between(start_time:, end_time:)
    issues = self.jira_issues_assigned_between(start_time: start_time, end_time: end_time)
    JiraProject.where(id: issues.collect(&:project_id).uniq)
  end

  def related_assignment_issues_between(start_time:, end_time:)
    projects = self.jira_projects_assigned_between(start_time: start_time, end_time: end_time)
    JiraIssue.where(project_id: projects.ids).where("opened_at BETWEEN ? AND ?", start_time, end_time)
  end

  def coassignees_between(start_time:, end_time:)
    issues = self.related_assignment_issues_between(start_time: start_time, end_time: end_time)
    Employee.where(id: issues.collect(&:assignee_id).uniq)
  end

  '''
  Proportion of all issues assigned to this user that are related to the given project
  '''
  def issue_assigned_proportion(project:)
    self.assigned_jira_issues.where(project: project).count.to_f / 
    self.assigned_jira_issues.count
  end

  def issue_assigned_proportion_between(project:, start_time:, end_time:)
    self.jira_issues_assigned_between(start_time: start_time, end_time: end_time).where(project: project).count.to_f / 
    self.jira_issues_assigned_between(start_time: start_time, end_time: end_time).count
  end

  '''
  Proportion of all issues assigned to this user that are related to the given project
  '''
  def issue_reported_proportion(project:)
    self.reported_jira_issues.where(project: project).count.to_f / 
    self.reported_jira_issues.count
  end

  '''
  Take all projects assigned to this employee and the given employee and sum the products of the
  proportional assignent of the employees per project
  '''
  def coassignment_weight(assignee:, assignee_proportions: nil)
    assignee_proportions ||= Hash.new

    shared_projects = self.assigned_jira_projects & assignee.assigned_jira_projects
    shared_projects.map do |p|
      known_assigned_proportion = assignee_proportions[self.id] || self.issue_assigned_proportion(project: p)
      known_assigned_proportion * assignee.issue_assigned_proportion(project: p)
    end.sum
  end

  def coassignment_weight_between(assignee:, assignee_proportions: nil, time_range:)
    assignee_proportions ||= Hash.new

    shared_projects = (
      self.jira_projects_assigned_between(start_time: time_range.begin, end_time: time_range.end) &
      assignee.jira_projects_assigned_between(start_time: time_range.begin, end_time: time_range.end)
    )
    shared_projects.map do |p|
      known_assigned_proportion = (
        assignee_proportions[self.id] ||
        self.issue_assigned_proportion_between(project: p, start_time: time_range.begin, end_time: time_range.end)
      )
      (
        known_assigned_proportion *
        assignee.issue_assigned_proportion_between(project: p, start_time: time_range.begin, end_time: time_range.end)
      )
    end.sum
  end

  '''
  Take all projects assigned to this employee and reported by the given employee and sum the products of the
  proportional assignent/reporting of the employees per project
  '''
  def assigned_reporter_weight(reporter:, assignee_proportions: Hash.new)
    shared_projects = self.assigned_jira_projects & reporter.reported_jira_projects
    shared_projects.map do |p|
      known_assigned_proportion = assignee_proportions[self.id] || self.issue_assigned_proportion(project: p)
      known_assigned_proportion * reporter.issue_reported_proportion(project: p)
    end.sum
  end

  '''
  Take all projects reported by this employee and the given employee and sum the products of the
  proportional reporting of the employees per project
  '''
  def coreporter_weight(reporter:, reporter_proportions: Hash.new)
    shared_projects = self.reported_jira_projects & reporter.reported_jira_projects
    shared_projects.map do |p|
      known_reported_proportion = reporter_proportions[self.id] || self.issue_reported_proportion(project: p)
      known_reported_proportion * reporter.issue_reported_proportion(project: p)
    end.sum
  end

  '''
  Take all projects reported by this employee and assigned to the given employee and sum the products of the
  proportional reporting/assignment of the employees per project
  '''
  def reporting_assignee_weight(assignee:, reporter_proportions: Hash.new)
    shared_projects = self.reported_jira_projects & assignee.assigned_jira_projects
    shared_projects.map do |p|
      known_reported_proportion = reporter_proportions[self.id] || self.issue_reported_proportion(project: p)
      known_reported_proportion * assignee.issue_assigned_proportion(project: p)
    end.sum
  end


  def weight_coassignments(assigned_project_proportions: nil, transform: false)
    coassignees = self.coassignees.where.not(id: self.id).to_a

    weights = Hash[
      weight_array = coassignees.map do |e|
        weight = self.coassignment_weight(
          assignee: e,
          assignee_proportions: assigned_project_proportions
        )
        weight = weight_to_distance(weight) if transform

        [e.id, weight]
      end
    ]

    coassignees.sort_by! {|e| weights[e.id] }
    coassignees.reverse! if !transform

    [coassignees, weights]
  end

  def weight_coassignments_between(assigned_project_proportions: nil, transform: false, time_range: nil)
    coassignees = self.coassignees_between(
      start_time: time_range.begin,
      end_time: time_range.end
    ).where.not(id: self.id).to_a

    weights = Hash[
      weight_array = coassignees.map do |e|
        weight = self.coassignment_weight_between(
          assignee: e,
          assignee_proportions: assigned_project_proportions,
          time_range: time_range
        )
        weight = weight_to_distance(weight) if transform

        [e.id, weight]
      end
    ]

    coassignees.sort_by! {|e| weights[e.id] }
    coassignees.reverse! if !transform

    [coassignees, weights]
  end

  def weight_to_distance(w)
    '''
    1 -> Closest (0)
    0 -> Furthest (100)
    Distribution probably is heavy on the small end
    TODO maybe target some distribution
    '''
    ((w-1)**2) * 200 + 25
  end
end
