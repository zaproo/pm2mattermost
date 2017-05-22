module OpenProject::Mattermost
  class Hooks < Redmine::Hook::Listener

    def mattermost_event_notification(context = {})
      event = MattermostEvent.find_or_create_by(context)
      job = SendMattermostMessageJob.new(event)
      Delayed::Job.enqueue(job, run_at: 5.seconds.from_now)
    end
  end
end
