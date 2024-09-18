# app/controllers/webhooks_controller.rb
class WebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token

  def google_calendar
    if valid_google_notification?
      process_notification(request)
      head :no_content # Respond with 204 No Content
    else
      head :unauthorized # Respond with 401 Unauthorized if verification fails
    end
  end

  private

  def valid_google_notification?
    # Optional: Validate the notification's authenticity
    true
  end

  def process_notification(request)
    notification = JSON.parse(request.body.read)
    event_type = request.headers['X-Goog-Resource-State']

    # Handle notification based on the event type (e.g., 'exists', 'deleted', 'sync')
    case event_type
    when 'sync'
      # Handle full sync
    when 'exists', 'updated'
      # Handle new or updated events
    when 'deleted'
      # Handle deleted events
    end
  end
end
