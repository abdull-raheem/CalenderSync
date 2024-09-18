class SyncCalendarJob
  include Sidekiq::Job

  def perform(user_id)
    user = User.find(user_id)
    user.calendars.each do |calendar|
      user.google_client.sync_calendar(calendar.google_calendar_id)
    end
  end
end