# OpenProject Mattermost Plugin

[OpenProject](https://www.openproject.org) plugin which allows listening some events (changing tasks status and adding/editing messages) and sends corresponding messages to [Mattermost](https://www.mattermost.org) chat rooms.

[Here](https://github.com/mattermost/docs/blob/master/source/developer/webhooks-incoming.md) is manual how to activate mattermost hooks.

## Install

To include the new plugin into OpenProject, you have to add it into Gemfile.plugins like any other OpenProject plugin. Add the following lines to Gemfile.plugins:

```
group :opf_plugins do
  gem "openproject-mattermost", git: "https://github.com/zaproo/pm2mattermost.git", :branch => "master"
end
```

After that run
```
bundle install
rake db:migrate
```

More information about OpenProject plugins you can get [here](https://www.openproject.org/open-source/development-free-project-management-software/create-openproject-plugin/).

After installing plugin go to the project settings page and on Modules tab activate Mattermost Settings option. After this you'll see Mattermost Settings menu (right underneath Project Settins) where you can set outcoming hook urls, enable tracking some events. Go to global plugin page for adjusting openproject to mattermost user syncronization table and set incoming hooks tokens.

## Incoming hooks (use POST method for all hooks)
- add message to task
```
http://[your-openproject-domain]/pm2mattermost/message
/pm [task_id] [message_text]
```
- view tasks list (current user is used if user is not specified in the command)
```
http://[your-openproject-domain]/pm2mattermost/tasks-list
/pmlist [mattermost_user_login]
/pmlist
```
- change task status
```
http://[your-openproject-domain]/pm2mattermost/update-task-status
/pmstatus [task_id] [open_project_status_name]
```
- change task assignee
```
http://[your-openproject-domain]/pm2mattermost/update-task-assignee
/pmassign [task_id] [mattermost_user_login]
```
- view task description
```
http://[your-openproject-domain]/pm2mattermost/project-description
/pmdesc [task_id]
```
