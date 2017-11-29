class IncomingHooksController < ActionController::Base
  before_action :authentificate_mattermost
  before_action :find_and_authorize_current_user
  before_action :decompose_message
  before_action :find_work_package, except: :tasks_list

  def message
    return unless authorize_adding_new_message

    @work_package.add_journal(@user, @message)

    if @work_package.save
      render json: response_data('Message is added succussfully')
    else
      render json: response_data("Message wasn't added. Check you command.")
    end
  end

  def tasks_list
    return unless authorize_getting_tasks_list

    assigned_to = @op_user.present? ? @op_user : @user

    tasks = WorkPackage.with_status_open.visible.where(assigned_to: assigned_to)
    tasks = tasks.where(project: assigned_to.projects) if @op_user.present?
    tasks = tasks.joins(:priority).order("enumerations.position desc")

    text = tasks.group_by(&:project).map do |p, t|
      table = "**Project**: #{p.name}\n\n" <<
              "| Task | Status | Priority | Subject |\n" <<
              "| :--: | :----- | :------- | :------ |\n"

      table << t.map do |work_package|
        "| [\##{work_package.id}](#{project_work_package_url(work_package.project, work_package)})" <<
        "| #{work_package.status}" <<
        "| #{work_package.priority.try(:name)}" <<
        "| #{work_package.subject}" <<
        "|\n"
      end.join

      table << "\n**Total**: **#{t.length}** tasks\n\n"
    end.join

    render json: response_data(text)
  end

  def update_task_status
    return unless find_work_package_status
    return unless authorize_changing_status

    if @work_package.update_attributes(status: @work_package_status)
      render json: response_data('Status is changed succussfully')
    else
      render json: response_data("Status wasn't changed. Check you command.")
    end
  end

  def update_task_assignee
    return unless find_openproject_user(@message, 'assignee')
    return unless authorize_changing_assignee

    if @work_package.update_attributes(assigned_to: @op_user)
      render json: response_data('Assignee is changed succussfully')
    else
      render json: response_data("Assignee wasn't changed. Check you command.")
    end
  end

  def project_description
    text = "**Project**: #{@project.name}\n" <<
           "**Description**: #{@project.description}\n" <<
           "**Task**: #{@work_package.subject}\n" <<
           "**Status**: #{@work_package.status}\n" <<
           "**Priority**: #{@work_package.priority.try(:name)}\n" <<
           "**Author**: #{@work_package.author}\n" <<
           "**Assigned to**: #{@work_package.assigned_to}"

    render json: response_data(text)
  end

  private

  def response_data(text)
    {
      response_type: 'ephemeral',
      text: text,
      username: @work_package.present? ? "PM (#{@project.name})" : 'PM'
    }
  end

  def authentificate_mattermost
    settings = Setting["plugin_openproject_mattermost"]
    tokens = settings["mattermost_incoming_hooks_tokens"].try(:split)

    is_valid = tokens.include?(params[:token]) if tokens.present?

    render(json: response_data('Authentification is failed'), status: 401) unless is_valid
    is_valid
  end

  def decompose_message
    data = params[:text].split
    @command_attr = data.shift
    @message = data.join(' ')
  end

  def find_work_package
    work_package_id = @command_attr.to_i

    @work_package = WorkPackage.visible.where(id: work_package_id).first if work_package_id
    @project = @work_package.project if @work_package.present?

    render(json: response_data("Wrong task id")) unless @work_package.present?
    @work_package.present?
  end

  def authorize_adding_new_message
    is_valid = @user.allowed_to?(:add_work_package_notes, @project) if @work_package.present?
    render(json: response_data("You're not allowed to add message to the task")) unless is_valid
    is_valid
  end

  def find_and_authorize_current_user
    @user = MattermostUser.where(name: params[:user_name]).first.try(:user)
    is_valid = @user.present? && @user.status != 3
    if is_valid
      User.current = @user
    else
      render(json: response_data('You are not registered in PM or locked'))
    end
    is_valid
  end

  def find_work_package_status
    @work_package_status = Status.where(name: @message).first
    render(json: response_data("Wrong status value")) unless @work_package_status.present?
    @work_package_status.present?
  end

  def authorize_changing_status
    is_valid = @work_package_status.present? &&
      @user.allowed_to?(:edit_work_packages, @project) &&
      @work_package.type.valid_transition?(
        @work_package.status.id,
        @work_package_status.id,
        @user.roles_for_project(@project)
      )

    render(json: response_data("You're not allowed to modify the task status")) unless is_valid
    is_valid
  end

  def find_openproject_user(name, attr_name='user')
    search_name = name.present? ? name.strip : ''
    search_name = search_name[0] == '@' ? search_name[1..-1] : search_name
    @op_user = MattermostUser.where(name: search_name).first.try(:user)
    render(json: response_data("Wrong #{attr_name} value")) unless @op_user.present?
    @op_user.present?
  end

  def authorize_changing_assignee
    is_valid = @op_user.present? &&
               @op_user.allowed_to?(:edit_work_packages, @project) &&
               @user.allowed_to?(:edit_work_packages, @project)

    render(json: response_data("You're not allowed to set this assignee to the task")) unless is_valid
    is_valid
  end

  def authorize_getting_tasks_list
    return true unless @command_attr.present?
    return false unless find_openproject_user(@command_attr)
    return true if @user.admin?

    is_valid = @op_user.projects.any? do |project|
      @user.allowed_to?(:manage_members, project) ||
      @user.allowed_to?(:view_members, project)
    end

    render(json: response_data("You're not allowed to get tasks list for the user")) unless is_valid
    is_valid
  end
end
