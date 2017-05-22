Rails.application.routes.draw do
  resources :mattermost_settings, only: [] do
    get :get_data, on: :collection
    post :update_data, on: :collection
    post :update_common_data, on: :collection
  end

  post '/pm2mattermost/message', controller: :incoming_hooks, action: :message
  post '/pm2mattermost/tasks-list', controller: :incoming_hooks, action: :tasks_list
  post '/pm2mattermost/update-task-status', controller: :incoming_hooks, action: :update_task_status
  post '/pm2mattermost/update-task-assignee', controller: :incoming_hooks, action: :update_task_assignee
  post '/pm2mattermost/project-description', controller: :incoming_hooks, action: :project_description
end
