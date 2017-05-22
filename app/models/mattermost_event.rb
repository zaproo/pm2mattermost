class MattermostEvent < ActiveRecord::Base
  belongs_to :journal

  validates_presence_of :journal

  def event_type
    details = journal.details
    case
    when details.has_key?(:subject) && !journal.old_value_for("subject")
      :created
    when !details.present? && journal.notes.present?
      :commented
    else
      :changed
    end
  end
end
