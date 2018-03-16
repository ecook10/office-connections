Office Connections
------------------
Create useful and intuitive maps of inter-office connections dynamically using data pulled from internal tools

# Setup
1. Install rails, webpacker and react
```console
$ bundle install
$ yarn install
```
2. Update `config/database.yml` with your local database configuration
3. Set `JIRA_DOMAIN`, `JIRA_USERNAME`, and `JIRA_PASSWORD` environment variables
4. Migrate and populate db (populate script take ~10 minutes to run)
```console
$ rails db:create
$ rails db:migrate
$ rails jira:populate
```
5. Start the rails server
```console
$ rails s
```

# TODO
+ Run in a Docker container and deploy to Porch dev cluster
+ Reduce query load (cache connections, better joining, ...)
+ Periodically update data
+ Show more connection data in side panel
+ Filter by date / state
+ Pull in data from more sources (GitLab?, HipChat?)
