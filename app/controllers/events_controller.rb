require 'ostruct'

class EventsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_calendar
  before_action :set_event, only: %i[edit update destroy]

  def index
    response = current_user.google_client.fetch_events(@calendar.google_calendar_id, Time.zone.now, 7.days.from_now)

    if response.is_a?(Net::HTTPSuccess)
      @events = JSON.parse(response.body)['items'] || []
    else
      Rails.logger.error("Failed to fetch events: #{response.body}")
      @events = []
      flash[:alert] = 'Failed to fetch events. Please try again.'
    end
  end

  def new
    @event = OpenStruct.new(
      summary: '',
      location: '',
      description: '',
      start: { 'dateTime' => '', 'date' => '' },
      end: { 'dateTime' => '', 'date' => '' }
    )
  end

  def create
    event_data = build_event_data(params)

    response = current_user.google_client.create_event(@calendar.google_calendar_id, event_data)

    if response.is_a?(Net::HTTPSuccess)
      redirect_to calendar_events_path(@calendar), notice: 'Event was successfully created.'
    else
      handle_api_error(response, :new, 'create')
    end
  end

  def edit
    response = current_user.google_client.fetch_event(@calendar.google_calendar_id, params[:id])

    if response.is_a?(Net::HTTPSuccess)
      event_data = JSON.parse(response.body)
      @event = OpenStruct.new(event_data)
    else
      handle_api_error(response, :index, 'edit')
    end
  end

  def update
    event_data = build_event_data(params)

    response = current_user.google_client.update_event(@calendar.google_calendar_id, params[:id], event_data)

    if response.is_a?(Net::HTTPSuccess)
      redirect_to calendars_path(@calendar), notice: 'Event was successfully updated.'
    else
      handle_api_error(response, :edit, 'update')
    end
  end

  def destroy
    response = current_user.google_client.delete_event(@calendar.google_calendar_id, params[:id])

    if response.is_a?(Net::HTTPSuccess)
      redirect_to calendar_path(@calendar), notice: 'Event was successfully deleted.'
    else
      handle_api_error(response, :index, 'delete')
    end
  end

  private

  def set_calendar
    @calendar = current_user.calendars.find(params[:calendar_id])
  end

  def set_event
    @event_id = params[:id]
  end

  def build_event_data(event_params)

    {
      summary: event_params[:summary],
      location: event_params[:location],
      description: event_params[:description],
      start: {
        dateTime: event_params[:start_time].present? ? "#{event_params[:start_time]}:00Z" : nil,
        timeZone: 'UTC'
      },
      end: {
        dateTime: event_params[:end_time].present? ? "#{event_params[:end_time]}:00Z" : nil,
        timeZone: 'UTC'
      }
    }
  end

  def handle_api_error(response, render_action, action)
    error_message = JSON.parse(response.body)['error']['message'] rescue response.body
    Rails.logger.error("Failed to #{action} event: #{error_message}")
    flash[:alert] = "Failed to #{action} event: #{error_message}"
    render render_action
  end
end
