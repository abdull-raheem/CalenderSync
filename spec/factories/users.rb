FactoryBot.define do
  factory :user do
    email { Faker::Internet.email }
    password { 'password123' }
    password_confirmation { 'password123' }
    provider { 'google_oauth2' }
    uid { SecureRandom.uuid }
    token { SecureRandom.hex(20) }
    refresh_token { SecureRandom.hex(20) }
    token_expires_at { 1.hour.from_now }

  
    trait :from_omniauth do
      after(:build) do |user|
        auth = OmniAuth::AuthHash.new(
          provider: 'google_oauth2',
          uid: SecureRandom.uuid,
          info: {
            email: user.email
          },
          credentials: {
            token: SecureRandom.hex(20),
            refresh_token: SecureRandom.hex(20),
            expires_at: 1.hour.from_now.to_i
          }
        )
        user.assign_attributes(User.from_omniauth(auth).attributes)
      end
    end
  end
end
