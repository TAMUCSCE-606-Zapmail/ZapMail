class User < ApplicationRecord
  # Enables password hashing and authentication
  has_secure_password

  # Associations
  has_many :templates, dependent: :destroy
  has_many :automations, dependent: :destroy

  # Validations
  validates :name, presence: true, length: { maximum: 50 }

  # Email: presence, uniqueness (case insensitive), format restricted to .com or .edu
  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.(com|edu)\z/i
  validates :email,
            presence: true,
            uniqueness: { case_sensitive: false },
            format: { with: VALID_EMAIL_REGEX, message: "must include @ and end with .com or .edu" }

  # Password: minimum length, optional on update if blank, confirmation support
  validates :password, length: { minimum: 8 }, allow_nil: true, confirmation: true

  # UIN: optional but unique and exactly 9 digits if present
  validates :uin, uniqueness: true, allow_blank: true, length: { is: 9 }, numericality: { only_integer: true }

  # Classification: optional but must be in the allowed list if present
  VALID_CLASSIFICATIONS = %w[Freshman Sophomore Junior Senior Graduate Other]
  validates :classification,
            inclusion: { in: VALID_CLASSIFICATIONS, message: "%{value} is not a valid classification" },
            allow_blank: true

  # Callbacks
  before_save :downcase_email

  private

  # Ensures emails are stored in lowercase
  def downcase_email
    self.email = email.downcase
  end
end
