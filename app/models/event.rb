class Event < ApplicationRecord
  belongs_to :calendar

  validates :google_event_id, presence: true, uniqueness: true

  def self.create_or_update_from_google_data(calendar, event_data)
    event = calendar.events.find_or_initialize_by(google_event_id: event_data['id'])
    event.update(
      summary: event_data['summary'],
      location: event_data['location'],
      description: event_data['description'],
      start_time: parse_google_date(event_data['start']),
      end_time: parse_google_date(event_data['end']),
      status: event_data['status']
    )
  end

  def self.parse_google_date(google_date)
    DateTime.parse(google_date['dateTime'] || google_date['date'])
  end
end
