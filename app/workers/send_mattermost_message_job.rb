require 'net/http'
require 'net/https'

class SendMattermostMessageJob < ApplicationJob
  include OpenProject::StaticRouting::UrlHelpers

  def initialize(event)
    @event = event
    @journal = @event.journal
    @work_package = @journal.journable
    @project = @journal.project
    @user = @journal.user
  end

  def perform
    send_message(message)
  end

  def success(job)
    events.destroy_all
  end

  protected

  def default_url_options
    {
      host: OpenProject::StaticRouting::UrlHelpers.host,
      only_path: false,
      script_name: OpenProject::Configuration.rails_relative_url_root
    }
  end

  private

  def message
    list = events_list
    if list.present?
      "Task: [\##{@work_package.id}]" <<
      "(#{project_work_package_url(@project, @work_package)}): **#{@work_package.subject}**: " <<
      "User: **#{@user}** has\n" <<
      "#{list}"
    end
  end

  def events_list
    events_by_type.map do |type, data|
      case
      when type == :created
        "* added a new task"
      when type == :commented
        data[:note].map { |note| "* commented: #{note}" }.join('\n')
      else
        %w(status_id assigned_to_id).map do |key|
          next if data[key].blank? or data[key].first == data[key].last
          send("changed_#{key}_message", data[key])
        end.compact.join('\n')
      end
    end.join('\n')
  end

  def changed_status_id_message(data)
    old_value = Status.find(data.first)
    new_value = Status.find(data.last)
    "* changed status from **#{old_value}** to **#{new_value}**"
  end

  def changed_assigned_to_id_message(data)
    old_value = User.where(id: data.first).first || 'unassigned'
    new_value = User.where(id: data.last).first || 'unassigned'
    "* changed assignee from **#{old_value}** to **#{new_value}**"
  end

  def send_message(message)
    urls = hook_urls
    return unless urls.present? or message.present?
    urls.each do |url|
      next unless url.present?
      uri = URI.parse(url)
      req = Net::HTTP::Post.new(uri.request_uri)
      req.body = "payload={\"username\": \"PM (#{@project.name})\", \"text\": \"#{message}\"}"
      res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.instance_of?(URI::HTTPS)) do |http|
        http.request(req)
      end
    end
  end

  def hook_urls
    @project
      .mattermost_settings
      .joins(:setting)
      .where(
        enabled: true,
        mattermost_settings: { kind: MattermostSetting.kinds[:outcoming_hook_url] }
      )
      .map(&:value)
  end

  def events
    @events ||= MattermostEvent.joins(:journal)
      .where(
        journals: {
          user_id: @user.id,
          journable_type: "WorkPackage",
          journable_id: @work_package.id
        }
      )
  end

  def events_by_type
    events.inject({}) do |result, event|
      event_data = result[event.event_type] || {}
      if event.event_type == :commented
        notes = fix_markup(event.journal.notes)
        event_data[:note] = ( event_data[:note] || [] ).concat([notes])
      else
        event.journal.details.each do |key, value|
          event_data[key] = ( event_data[key] || [] ).concat(value)
        end
      end
      result[event.event_type] = event_data
      result
    end
  end

  def fix_markup(text)
    text.gsub(/^\s*[#*]\s+/m, ' * ')
        .gsub(/\s*(\#+)\s+/, ' _\1_ ')
        .gsub(/user\#\d+/) do |result|
           id = result.split('#').last
           user = User.find_by(id: id)
           mm_user = user&.mattermost_user&.name || user&.login || result
           "@#{mm_user}"
         end
  end
end
