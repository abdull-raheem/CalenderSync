# Calendar Sync Project

## Overview

The Calendar Sync project is a Ruby on Rails application that integrates with Google Calendar to manage events directly from the app. It uses OAuth 2.0 for authentication and authorization, allowing users to interact with their Google Calendar accounts securely.

## Features

- **User Authentication**: Sign up, login, and password recovery using Devise.
- **Google Calendar Integration**: Add, edit, delete, and list events from your Google Calendar.
- **OAuth 2.0 Authentication**: Securely connect your Google account to manage calendar events.
- **Event Management**: Create, update, and delete calendar events with ease.
- **Error Handling**: Graceful error messages and handling of Google API failures.

## Technologies Used

- **Ruby on Rails**: Backend framework
- **Devise**: Authentication and user management
- **OmniAuth**: Google OAuth 2.0 integration
- **Google Calendar API**: For calendar event management
- **RSpec**: Testing framework
- **FactoryBot**: Test data generation
- **WebMock**: HTTP request stubbing (alternative mocking approach in use)

## Setup and Installation


### Prerequisites

- Ruby (>= 3.0)
- Rails (>= 7.0)
- PostgreSQL (or any preferred database)
- Google Developer Account for API credentials

### Google OAuth Setup
- **Go to Google Developers Console**
- Create a new project.
- Enable the Google Calendar API.
- Create OAuth 2.0 credentials:
- Authorized redirect URI: http://localhost:3000/users/auth/google_oauth2/callback
- Copy the Client ID and Client Secret into your .env file as shown above.

### Installation

1. **Clone the Repository**
   ```bash
   git clone https://github.com/yourusername/calendar-sync.git
   cd calendar-sync
2. **Install Dependencies**
    ```bash
   bundle install
3. **Set Up Environment Variables**
   Create a .env file in the root directory and add your Google API credentials:
    ```bash
    GOOGLE_CLIENT_ID=your_google_client_id
    GOOGLE_CLIENT_SECRET=your_google_client_secret
4. **Migrate DB**
    ```bash
    rails db:migrate
5. **Start Server**
    ```bash
    rails s

### Testing

In order to run Test cases run the below command
  ```bash
    rspec
