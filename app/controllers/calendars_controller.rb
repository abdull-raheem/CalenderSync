class CalendarsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_calendar, only: %i[show edit update destroy]

  def index
    @calendars = current_user.calendars
  end

  def show
    @events = @calendar.fetch_events(Time.zone.now, 7.days.from_now)
  end

  def new
    @calendar = current_user.calendars.build
  end

  def create
    @calendar = current_user.calendars.build(calendar_params)

    if @calendar.save
      redirect_to calendars_path, notice: 'Calendar was successfully created.'
    else
      render :new
    end
  end

  def edit; end

  def update
    if @calendar.update(calendar_params)
      redirect_to calendars_path, notice: 'Calendar was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    @calendar.destroy
    redirect_to calendars_path, notice: 'Calendar was successfully deleted.'
  end

  private

  def set_calendar
    @calendar = current_user.calendars.find(params[:id])
  end

  def calendar_params
    params.require(:calendar).permit(:name, :google_calendar_id, :timezone)
  end
end
