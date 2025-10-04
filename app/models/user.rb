class User < ApplicationRecord
    # Adds methods to set and authenticate against a BCrypt password.
    # This requires a `password_digest` attribute.
    has_secure_password
  
    has_many :templates, dependent: :destroy
    
    # Validations
    validates :name, presence: true, length: { maximum: 50 }
    validates :email, presence: true,
                      uniqueness: { case_sensitive: false },
                      format: { with: URI::MailTo::EMAIL_REGEXP }
    validates :password, length: { minimum: 8 }, if: -> { new_record? || !password.nil? }
    validates :uin, uniqueness: true, allow_blank: true, length: { is: 9 }, numericality: { only_integer: true }
    validates :classification, inclusion: { in: %w[Freshman Sophomore Junior Senior Graduate Other],
      message: "%{value} is not a valid classification" }, allow_blank: true
  
    # Callbacks
    before_save :downcase_email
  
    private
  
    # Converts email to all lower-case for consistency.
    def downcase_email
      self.email = email.downcase
    end


  #emaiL issue
  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.(com|edu)\z/i

  validates :email, presence: true,
                    format: { with: VALID_EMAIL_REGEX,
                              message: "must include @ and end with .com or .edu" }
# password 
  validates :password, length: { minimum: 8 }, allow_blank: true
  validates :password, confirmation: true, allow_blank: true


end
class User < ApplicationRecord
    # Adds methods to set and authenticate against a BCrypt password.
    # This requires a `password_digest` attribute.
    has_secure_password
  
    has_many :templates, dependent: :destroy
    has_many :automations, dependent: :destroy
    
    # Validations
    validates :name, presence: true, length: { maximum: 50 }
    validates :email, presence: true,
                      uniqueness: { case_sensitive: false },
                      format: { with: URI::MailTo::EMAIL_REGEXP }
    validates :password, length: { minimum: 8 }, if: -> { new_record? || !password.nil? }
    validates :uin, uniqueness: true, allow_blank: true, length: { is: 9 }, numericality: { only_integer: true }
    validates :classification, inclusion: { in: %w[Freshman Sophomore Junior Senior Graduate Other],
      message: "%{value} is not a valid classification" }, allow_blank: true
  
    # Callbacks
    before_save :downcase_email
  
    private
  
    # Converts email to all lower-case for consistency.
    def downcase_email
      self.email = email.downcase
    end
  end
