class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def google_oauth2
    user = User.from_omniauth(request.env['omniauth.auth'])

    if user.persisted?
      sign_in_and_redirect user, event: :authentication
      fetch_and_save_calendars(user) # Fetch and save calendars after login
      flash[:notice] = 'Successfully authenticated from Google account.' if is_navigational_format?
    else
      session['devise.google_data'] = request.env['omniauth.auth'].except('extra')
      redirect_to new_user_registration_url, alert: user.errors.full_messages.join("\n")
    end
  end

  private

  def fetch_and_save_calendars(user)
    google_client = GoogleClient.new(user)
    response = google_client.list_calendars

    if response.is_a?(Net::HTTPSuccess)
      calendars = JSON.parse(response.body)['items']
      calendars.each do |calendar_data|
        user.calendars.find_or_create_by(google_calendar_id: calendar_data['id']) do |calendar|
          calendar.name = calendar_data['summary']
          calendar.timezone = calendar_data['timeZone']
        end
      end
    else
      Rails.logger.error("Failed to fetch calendars: #{response.body}")
      flash[:alert] = 'Failed to fetch calendars. Please try again.'
    end
  end
end
