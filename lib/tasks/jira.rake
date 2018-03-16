namespace :jira do
  require 'net/http'
  require 'json'

  desc "Collect all current Jira issues and populate models"
  task populate: :environment do
    errors = Array.new

    start_at = 0
    page_size = 100
    loop do
      uri = search_uri(start_at, page_size)
      request = auth_request(uri)

      response = JSON.parse(
        Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
          http.request(request)
        end.body
      )
      break if response['issues'].empty?

      response['issues'].each do |issue|
        begin
          assignee = nil
          if issue['fields']['assignee']
            assignee = Employee.find_or_create_by(
              jira_key: issue['fields']['assignee']['key'],
              name: issue['fields']['assignee']['name']
            )
          end
          reporter = Employee.find_or_create_by(
            jira_key: issue['fields']['reporter']['key'],
            name: issue['fields']['reporter']['name']
          )
          project = JiraProject.find_or_create_by(
            key: issue['fields']['project']['key'],
            name: issue['fields']['project']['name']
          )
          JiraIssue.create!(
            key: issue['key'],
            summary: issue['fields']['summary'],
            status_name: issue['fields']['status']['name'],
            reporter: reporter,
            project: project,
            assignee: assignee
          )

        rescue StandardError => e
          puts "Error! -> #{e}"
          errors << { issue_data: issue, error: e }
        end
      end

      start_at += page_size
      print "\rCompletion: #{(start_at.to_f / response['total'] * 100).to_i}%"
    end

    puts "\nCompleted with #{errors.count} errors"
    puts "Errors:"
    puts errors
    puts
  end

  desc "Update all Jira issues with when they were opened"
  task populate_opened_at: :environment do
    errors = Array.new

    start_at = 0
    page_size = 100
    loop do
      uri = search_uri(start_at, page_size, 'created,assignee,')
      request = auth_request(uri)

      response = JSON.parse(
        Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
          http.request(request)
        end.body
      )
      break if response['issues'].empty?

      response['issues'].each do |issue_data|
        begin
          issue = JiraIssue.find_by(key: issue_data['key'])
          issue && issue.update!(opened_at: Time.parse(issue_data['fields']['created']).utc)
        rescue StandardError => e
          puts "Error! -> #{e}"
          errors << { issue_data: issue, error: e }
        end
      end

      start_at += page_size
      print "\rCompletion: #{(start_at.to_f / response['total'] * 100).to_i}%"
    end

    puts "\nCompleted with #{errors.count} errors"
    puts "Errors:"
    puts errors
    puts
  end

  def self.search_uri(start_at, page_size, fields='summary,assignee,status,reporter,project')
    uri = URI.parse("https://#{ENV['JIRA_DOMAIN']}.atlassian.net/rest/api/2/search")
    params = {
      fields: fields,
      startAt: start_at,
      maxResults: page_size
    }
    uri.query = URI.encode_www_form(params)
    uri
  end

  def auth_request(uri)
    request = Net::HTTP::Get.new(uri)
    request.basic_auth(ENV['JIRA_USERNAME'], ENV['JIRA_PASSWORD'])
    request
  end

end
