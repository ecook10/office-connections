class EmployeesController < ApplicationController

  def index
    @employees = Employee.all
  end

  def show
    @employee = Employee.find(params[:id])

    @assigned_projects = @employee.assigned_jira_projects.to_a
    @assigned_project_proportions = Hash[
      @assigned_projects.map {|p| [p.id, @employee.issue_assigned_proportion(project: p)] }
    ]
    @assigned_projects.sort_by! {|p| @assigned_project_proportions[p.id] }.reverse!

    @coassignees, @coassignment_weights = @employee.weight_coassignments(
      assigned_project_proportions: @assigned_project_proportions
    )

    @assigned_reporters = @employee.assigned_reporters.where.not(id: @employee.id).to_a
    @assigned_reporter_weights = Hash[
      @assigned_reporters.map do |e|
        [
          e.id,
          @employee.assigned_reporter_weight(
            reporter: e,
            assignee_proportions: @assigned_project_proportions
          )
        ]
      end
    ]
    @assigned_reporters.sort_by! {|e| @assigned_reporter_weights[e.id] }.reverse!

    @reported_projects = @employee.reported_jira_projects.to_a
    @reported_project_proportions = Hash[
      @reported_projects.map {|p| [p.id, @employee.issue_reported_proportion(project: p)] }
    ]
    @reported_projects.sort_by! {|p| @reported_project_proportions[p.id] }.reverse!

    @coreporters = @employee.coreporters.where.not(id: @employee.id).to_a
    @coreporter_weights = Hash[
      @coreporters.map do |e|
        [
          e.id,
          @employee.coreporter_weight(
            reporter: e,
            reporter_proportions: @reported_project_proportions
          )
        ]
      end
    ]
    @coreporters.sort_by! {|e| @coreporter_weights[e.id] }.reverse!

    @reporting_assignees = @employee.reporting_assignees.where.not(id: @employee.id).to_a
    @reporting_assignee_weights = Hash[
      @reporting_assignees.map do |e|
        [
          e.id,
          @employee.reporting_assignee_weight(
            assignee: e,
            reporter_proportions: @reported_project_proportions
          )
        ]
      end
    ]
    @reporting_assignees.sort_by! {|e| @reporting_assignee_weights[e.id] }.reverse!
  end

  def coassignee_graph
    @employee = Employee.find(params[:id])
    assigned_projects = @employee.assigned_jira_projects.to_a
    @assigned_project_proportions = Hash[
      assigned_projects.map {|p| [p.id, @employee.issue_assigned_proportion(project: p)] }
    ]
    coassignees, weights = @employee.weight_coassignments(
      assigned_project_proportions: @assigned_project_proportions,
      transform: true
    )
    assigned_projects.sort_by! {|p| @assigned_project_proportions[p.id] }.reverse!
    @assigned_project_objects = assigned_projects.map do |project|
      {
        id: project.id,
        name: project.name
      }
    end

    # For now, only show top 10 connections
    display_coassignees = coassignees[0..10]

    node_names = Set[@employee.name]
    link_names = Set.new
    @employee_node = { name: @employee.name, degree: 0 }
    @connection_data = {
      nodes: [@employee_node],
      links: Array.new
    }
    display_coassignees.each do |coassignee|
      if node_names.add?(coassignee.name)
        @connection_data[:nodes] << { name: coassignee.name, degree: 1 }
      end
      if link_names.add?([@employee.name, coassignee.name].sort)
        @connection_data[:links] << {
          source: @employee.name,
          target: coassignee.name,
          distance: weights[coassignee.id],
          degree: 1
        }
      end
    end

    @connection_data2 = {
      nodes: @connection_data[:nodes].dup,
      links: @connection_data[:links].dup
    }
    display_coassignees.each do |coassignee|
      coassignees2, weights2 = coassignee.weight_coassignments(transform: true)
      coassignees2.select {|c| c != @employee }[0..10].each do |coassignee2|
        if node_names.add?(coassignee2.name)
          @connection_data2[:nodes] << { name: coassignee2.name, degree: 2 }
        end
        if link_names.add?([coassignee.name, coassignee2.name].sort)
          @connection_data2[:links] << {
            source: coassignee.name,
            target: coassignee2.name,
            distance: weights2[coassignee2.id],
            degree: 2
          }
        end
      end
    end

    @connection_data[:nodes].reverse!
    @connection_data[:links].reverse!

    @connection_data2[:nodes].reverse!
    @connection_data2[:links].reverse!
  end

  def coassignee_graph_between
    @employee = Employee.find(params[:id])

    start_time = params[:start_time] && Time.parse(params[:start_time]) || Time.at(0)
    end_time = params[:end_time] && Time.parse(params[:end_time]) || Time.now
    @time_range = start_time..end_time

    coassignees, weights = @employee.weight_coassignments_between(transform: true, time_range: @time_range)

    # For now, only show top 10 connections
    display_coassignees = coassignees[0..10]

    node_names = Set[@employee.name]
    link_names = Set.new
    @employee_node = { name: @employee.name, degree: 0 }
    @connection_data = {
      nodes: [@employee_node],
      links: Array.new
    }
    display_coassignees.each do |coassignee|
      if node_names.add?(coassignee.name)
        @connection_data[:nodes] << { name: coassignee.name, degree: 1 }
      end
      if link_names.add?([@employee.name, coassignee.name].sort)
        @connection_data[:links] << {
          source: @employee.name,
          target: coassignee.name,
          distance: weights[coassignee.id],
          degree: 1
        }
      end
    end

    @connection_data2 = {
      nodes: @connection_data[:nodes].dup,
      links: @connection_data[:links].dup
    }
    display_coassignees.each do |coassignee|
      coassignees2, weights2 = coassignee.weight_coassignments_between(transform: true, time_range: @time_range)
      coassignees2.select {|c| c != @employee }[0..10].each do |coassignee2|
        if node_names.add?(coassignee2.name)
          @connection_data2[:nodes] << { name: coassignee2.name, degree: 2 }
        end
        if link_names.add?([coassignee.name, coassignee2.name].sort)
          @connection_data2[:links] << {
            source: coassignee.name,
            target: coassignee2.name,
            distance: weights2[coassignee2.id],
            degree: 2
          }
        end
      end
    end

    @connection_data[:nodes].reverse!
    @connection_data[:links].reverse!

    @connection_data2[:nodes].reverse!
    @connection_data2[:links].reverse!
  end

end
