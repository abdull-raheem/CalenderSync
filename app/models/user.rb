class User < ApplicationRecord
  has_many :calendars, dependent: :destroy

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :omniauthable, omniauth_providers: [:google_oauth2]

  def self.from_omniauth(auth)
    where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      user.email = auth.info.email
      user.password = Devise.friendly_token[0, 20]
      user.token = auth.credentials.token
      user.refresh_token = auth.credentials.refresh_token
      user.token_expires_at = Time.at(auth.credentials.expires_at) if auth.credentials.expires_at
    end
  end

  def google_client
    @google_client ||= GoogleClient.new(self)
  end

  def refresh_access_token!
    google_client.refresh_access_token
  end
end
