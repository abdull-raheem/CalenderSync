require 'net/http'
require 'json'

class GoogleClient
  API_BASE_URL = 'https://www.googleapis.com/calendar/v3/calendars'.freeze

  def initialize(user)
    @user = user
    refresh_access_token if token_expired?
  end

  def list_calendars
    uri = URI("https://www.googleapis.com/calendar/v3/users/me/calendarList")
    request(:get, uri)
  end

  def fetch_event(calendar_id, event_id)
    uri = URI("#{API_BASE_URL}/#{calendar_id}/events/#{event_id}")
    request(:get, uri)
  end

  def create_event(calendar_id, event_data)
    uri = URI("#{API_BASE_URL}/#{calendar_id}/events")
    request(:post, uri, event_data)
  end

  def update_event(calendar_id, event_id, event_data)
    uri = URI("#{API_BASE_URL}/#{calendar_id}/events/#{event_id}")
    request(:patch, uri, event_data)
  end

  def delete_event(calendar_id, event_id)
    uri = URI("#{API_BASE_URL}/#{calendar_id}/events/#{event_id}")
    request(:delete, uri)
  end

  def fetch_events(calendar_id, start_time, end_time)
    uri = URI("#{API_BASE_URL}/#{calendar_id}/events")
    uri.query = URI.encode_www_form(
      timeMin: start_time.iso8601,
      timeMax: end_time.iso8601,
      singleEvents: true,
      orderBy: 'startTime'
    )
    request(:get, uri)
  end

  private

  def handle_watch_response(response)
    if response.is_a?(Net::HTTPSuccess)
      Rails.logger.info("Successfully subscribed to calendar changes: #{response.body}")
    else
      error_message = JSON.parse(response.body)['error']['message'] rescue response.body
      Rails.logger.error("Failed to subscribe to calendar changes: #{error_message}")
    end
  end

  def token_expired?
    @user.token_expires_at.nil? || @user.token_expires_at < Time.zone.now
  end

  def refresh_access_token
    uri = URI('https://oauth2.googleapis.com/token')
    response = Net::HTTP.post_form(uri, {
      'client_id' => ENV['GOOGLE_CLIENT_ID'],
      'client_secret' => ENV['GOOGLE_CLIENT_SECRET'],
      'refresh_token' => @user.refresh_token,
      'grant_type' => 'refresh_token'
    })

    tokens = JSON.parse(response.body)
    if response.is_a?(Net::HTTPSuccess) && tokens['access_token']
      @user.update!(
        token: tokens['access_token'],
        token_expires_at: Time.zone.now + tokens['expires_in'].seconds
      )
    else
      raise "Failed to refresh access token: #{tokens['error_description']}"
    end
  end

  def request(method, uri, body = nil)
    request = build_request(method, uri, body)
    execute_request(uri, request)
  end

  def build_request(method, uri, body)
    request_class = {
      get: Net::HTTP::Get,
      post: Net::HTTP::Post,
      patch: Net::HTTP::Patch,
      delete: Net::HTTP::Delete
    }[method]

    request = request_class.new(uri)
    request['Authorization'] = "Bearer #{@user.token}"
    request['Content-Type'] = 'application/json' if body
    request.body = body.to_json if body
    request
  end

  def execute_request(uri, request)
    Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      response = http.request(request)
      unless response.is_a?(Net::HTTPSuccess)
        Rails.logger.error("HTTP Request failed: #{response.code} #{response.message}")
        raise "HTTP Request failed: #{response.code} #{response.message}"
      end
      response
    end
  end
end
