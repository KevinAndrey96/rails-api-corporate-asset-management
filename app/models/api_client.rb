# A system integration allowed to call the API with a bearer token. Only the SHA-256 digest of the token is stored.
class ApiClient < ApplicationRecord
  TOKEN_BYTES = 32
  MINIMUM_TOKEN_LENGTH = 32

  enum :access, { reader: 0, editor: 1 }, validate: true

  validates :name, presence: true, uniqueness: true, length: { maximum: 80 }
  validates :token_digest, presence: true, uniqueness: true

  scope :active, -> { where(revoked_at: nil) }

  def self.digest(token)
    OpenSSL::Digest::SHA256.hexdigest(token.to_s)
  end

  # Returns the client and its plain token, which is never persisted and cannot be recovered later.
  def self.issue!(name:, access:, token: SecureRandom.base58(TOKEN_BYTES))
    raise ArgumentError, "token must have at least #{MINIMUM_TOKEN_LENGTH} characters" if token.length < MINIMUM_TOKEN_LENGTH

    [ create!(name: name, access: access, token_digest: digest(token)), token ]
  end

  def self.authenticate(token)
    return if token.blank?

    active.find_by(token_digest: digest(token))
  end

  def revoke!
    update!(revoked_at: Time.current)
  end
end
