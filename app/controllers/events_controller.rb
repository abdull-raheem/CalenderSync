require 'net/http'
require 'json'

class EventsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_google_credentials
  before_action :set_calendar_id, only: %i[index create edit update destroy]
  before_action :fetch_event, only: %i[edit update destroy]

  def index
    @events = fetch_events(Time.zone.now, 7.days.from_now)
    render :index
  end

  def new
    @event = default_event_structure
    @start_time = format_datetime(Time.zone.now)
    @end_time = format_datetime(1.hour.from_now)
  end

  def create
    event_data = build_event_data(params[:summary], params[:location], params[:description],
                                  params[:start_time], params[:end_time])
    response = google_api_request(:post, events_url, event_data)

    handle_response(response, 'create', :new)
  end

  def edit
    @event ||= default_event_structure
    @start_time = format_datetime(@event.dig('start', 'dateTime') || @event.dig('start', 'date'))
    @end_time = format_datetime(@event.dig('end', 'dateTime') || @event.dig('end', 'date'))
  end

  def update
    event_data = build_event_data(params[:summary], params[:location], params[:description], params[:start_time], params[:end_time])
    response = google_api_request(:patch, event_url(params[:id]), event_data)

    handle_response(response, "updated", :edit)
  end

  def destroy
    response = google_api_request(:delete, event_url(params[:id]))

    handle_response(response, "deleted", :index, redirect_path: events_path)
  end

  private

  def set_calendar_id
    @calendar_id = 'primary'
  end

  def fetch_events(time_min, time_max)
    uri = URI("https://www.googleapis.com/calendar/v3/calendars/#{@calendar_id}/events")
    uri.query = URI.encode_www_form(
      timeMin: time_min.iso8601,
      timeMax: time_max.iso8601,
      singleEvents: true,
      orderBy: 'startTime'
    )
    response = google_api_request(:get, uri)
    JSON.parse(response.body)['items'] || []
  end

  def fetch_event
    response = google_api_request(:get, event_url(params[:id]))
    if response.is_a?(Net::HTTPSuccess)
      @event = JSON.parse(response.body)
      @start_time = format_datetime(@event.dig('start', 'dateTime') || @event.dig('start', 'date'))
      @end_time = format_datetime(@event.dig('end', 'dateTime') || @event.dig('end', 'date'))
    else
      handle_failed_event_fetch(response)
    end
  end

  def handle_failed_event_fetch(response)
    Rails.logger.error("Failed to fetch event: #{response.body}")
    flash[:alert] = 'Failed to load the event. Please try again.'
    redirect_to events_path
  end

  def build_event_data(summary, location, description, start_time, end_time)
    {
      summary: summary,
      location: location,
      description: description,
      start: {
        dateTime: "#{start_time}:00Z",
        timeZone: 'UTC'
      },
      end: {
        dateTime: "#{end_time}:00Z",
        timeZone: 'UTC'
      }
    }
  end

  def handle_response(response, action, render_action, redirect_path: events_path)
    if response.is_a?(Net::HTTPSuccess)
      redirect_to redirect_path, notice: "Event #{action} successfully."
    else
      error_details = parse_error(response)
      Rails.logger.error("Failed to #{action} event: #{error_details}")
      flash[:alert] = "Failed to #{action} event: #{error_details}"
      render render_action
    end
  end

  def google_api_request(method, url, body = nil)
    uri = URI(url)
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
    request['Authorization'] = "Bearer #{@access_token}"
    request['Content-Type'] = 'application/json' if body
    request.body = body.to_json if body
    request
  end

  def execute_request(uri, request)
    Net::HTTP.start(uri.hostname, uri.port, use_ssl: true, verify_mode: OpenSSL::SSL::VERIFY_PEER) do |http|
      http.request(request)
    end
  end

  def parse_error(response)
    JSON.parse(response.body)['error']['message'] rescue response.body
  end

  def default_event_structure
    {
      'summary' => '',
      'location' => '',
      'description' => '',
      'start' => { 'dateTime' => '' },
      'end' => { 'dateTime' => '' }
    }
  end

  def events_url
    "https://www.googleapis.com/calendar/v3/calendars/#{@calendar_id}/events"
  end

  def event_url(event_id)
    "https://www.googleapis.com/calendar/v3/calendars/#{@calendar_id}/events/#{event_id}"
  end

  def set_google_credentials
    if current_user.token_expires_at && current_user.token_expires_at < Time.zone.now
      refresh_access_token(current_user.refresh_token)
    else
      @access_token = current_user.token
    end
  end

  def refresh_access_token(refresh_token)
    client_id = ENV['GOOGLE_CLIENT_ID']
    client_secret = ENV['GOOGLE_CLIENT_SECRET']

    uri = URI('https://oauth2.googleapis.com/token')
    response = Net::HTTP.post_form(uri, {
      'client_id' => client_id,
      'client_secret' => client_secret,
      'refresh_token' => refresh_token,
      'grant_type' => 'refresh_token'
    })

    tokens = JSON.parse(response.body)

    if response.is_a?(Net::HTTPSuccess) && tokens['access_token']
      current_user.update(
        token: tokens['access_token'],
        token_expires_at: Time.zone.now + tokens['expires_in'].seconds
      )
      @access_token = tokens['access_token']
    else
      handle_token_refresh_error(tokens, response)
    end
  end

  def handle_token_refresh_error(tokens, response)
    error_message = tokens['error_description'] || tokens['error'] || response.body
    Rails.logger.error("Failed to refresh token: #{error_message}")

    case tokens['error']
    when 'invalid_grant'
      Rails.logger.error('Invalid grant error: refresh token might be expired or revoked.')
    when 'unauthorized_client'
      Rails.logger.error('Unauthorized client: Check your client ID and secret.')
    else
      Rails.logger.error('Unknown error occurred while refreshing token.')
    end

    redirect_to new_user_session_path, alert: 'Session expired, please log in again.'
  end

  def format_datetime(date_time)
    date_time.is_a?(String) ? DateTime.parse(date_time).strftime('%Y-%m-%dT%H:%M') : date_time.strftime('%Y-%m-%dT%H:%M')
  end
end
