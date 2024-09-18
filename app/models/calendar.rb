class Calendar < ApplicationRecord
  belongs_to :user
  has_many :events, dependent: :destroy

  validates :google_calendar_id, presence: true, uniqueness: true

  def fetch_events(start_time, end_time)
    response = user.google_client.fetch_events(google_calendar_id, start_time, end_time)
    JSON.parse(response.body)['items'] || []
  end
end
