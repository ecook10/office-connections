Rails.application.routes.draw do
  resources :jira_projects, only: [:index, :show]

  resources :employees, only: [:index, :show] do
    member do
      get 'coassignee_graph'
      get 'coassignee_graph_between'
    end
  end

  namespace :tests do
    get 'simple_graph'
  end
end
