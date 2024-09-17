require 'rails_helper'

RSpec.describe EventsController, type: :controller do
  # let(:user) { create(:user) }
  let(:calendar_id) { 'primary' }
  let(:event) do
    {
      'id' => 'event_id',
      'summary' => 'Test Event',
      'location' => 'Test Location',
      'description' => 'Test Description',
      'start' => { 'dateTime' => '2024-09-17T10:00:00Z' },
      'end' => { 'dateTime' => '2024-09-17T11:00:00Z' }
    }
  end

  # before do
  #   sign_in user
  #   allow(controller).to receive(:set_google_credentials).and_return(true) # Prevent actual Google API call
  #   allow(controller).to receive(:@access_token).and_return('valid_access_token')
  # end

  describe 'GET #index' do
    it 'fetches events and renders the index template' do
      allow(controller).to receive(:fetch_events).and_return([event]) # Mock fetch_events method

      get :index

      expect(assigns(:events)).to eq([event])
      expect(response).to render_template(:index)
    end
  end

  describe 'GET #new' do
    it 'initializes a new event and renders the new template' do
      get :new

      expect(assigns(:event)).to eq({
        'summary' => '',
        'location' => '',
        'description' => '',
        'start' => { 'dateTime' => '' },
        'end' => { 'dateTime' => '' }
      })
      expect(response).to render_template(:new)
    end
  end

  describe 'POST #create' do
    let(:event_params) do
      {
        summary: 'New Event',
        location: 'New Location',
        description: 'New Description',
        start_time: '2024-09-17T10:00',
        end_time: '2024-09-17T11:00'
      }
    end

    it 'creates a new event and redirects to the index' do
      allow(controller).to receive(:google_api_request).and_return(double('response', code: '200', body: event.to_json))

      post :create, params: { event: event_params }

      expect(response).to redirect_to(events_path)
      expect(flash[:notice]).to eq('Event created successfully.')
    end

    it 'handles errors and renders new template on failure' do
      allow(controller).to receive(:google_api_request).and_return(double('response', code: '400', body: { error: { message: 'Invalid data' } }.to_json))

      post :create, params: { event: event_params }

      expect(response).to render_template(:new)
      expect(flash[:alert]).to eq('Failed to create event: Invalid data')
    end
  end

  describe 'GET #edit' do
    it 'fetches the event and renders the edit template' do
      allow(controller).to receive(:fetch_event).and_return(event) # Mock fetch_event method

      get :edit, params: { id: 'event_id' }

      expect(assigns(:event)).to eq(event)
      expect(response).to render_template(:edit)
    end
  end

  describe 'PATCH #update' do
    let(:updated_event_params) do
      {
        summary: 'Updated Event',
        location: 'Updated Location',
        description: 'Updated Description',
        start_time: '2024-09-17T12:00',
        end_time: '2024-09-17T13:00'
      }
    end

    it 'updates the event and redirects to index' do
      allow(controller).to receive(:google_api_request).and_return(double('response', code: '200', body: event.to_json))

      patch :update, params: { id: 'event_id', event: updated_event_params }

      expect(response).to redirect_to(events_path)
      expect(flash[:notice]).to eq('Event updated successfully.')
    end

    it 'handles errors and renders edit template on failure' do
      allow(controller).to receive(:google_api_request).and_return(double('response', code: '400', body: { error: { message: 'Update failed' } }.to_json))

      patch :update, params: { id: 'event_id', event: updated_event_params }

      expect(response).to render_template(:edit)
      expect(flash[:alert]).to eq('Failed to update event: Update failed')
    end
  end

  describe 'DELETE #destroy' do
    it 'deletes the event and redirects to index' do
      allow(controller).to receive(:google_api_request).and_return(double('response', code: '204'))

      delete :destroy, params: { id: 'event_id' }

      expect(response).to redirect_to(events_path)
      expect(flash[:notice]).to eq('Event deleted successfully.')
    end

    it 'handles errors on failure to delete event' do
      allow(controller).to receive(:google_api_request).and_return(double('response', code: '400', body: { error: { message: 'Delete failed' } }.to_json))

      delete :destroy, params: { id: 'event_id' }

      expect(response).to redirect_to(events_path)
      expect(flash[:alert]).to eq('Failed to load the event. Please try again.')
    end
  end
end
