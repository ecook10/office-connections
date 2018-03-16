class JiraProjectsController < ApplicationController

  def index
    @projects = JiraProject.all
  end

  def show
    @project = JiraProject.find(params[:id])

    @assignees = @project.assignees.to_a
    @assignee_proportions = Hash[
      @assignees.map {|a| [a.id, @project.assignee_proportion(assignee: a)] }
    ]
    @assignees.sort_by! {|a| @assignee_proportions[a.id] }.reverse!

    @reporters = @project.reporters.to_a
    @reporter_proportions = Hash[
      @reporters.map {|r| [r.id, @project.reporter_proportion(reporter: r)] }
    ]
    @reporters.sort_by! {|r| @reporter_proportions[r.id] }.reverse!
  end
end
