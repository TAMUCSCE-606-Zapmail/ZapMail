# app/models/automation_history.rb
class AutomationHistory < ApplicationRecord
  belongs_to :automation

  scope :search, ->(query) {
    return all if query.blank?

    q = "%#{query.downcase}%"
    joins(automation: :strategy).where(
      "LOWER(automation_histories.row_data ->> 'email') LIKE :q
       OR LOWER(automation_histories.api_response) LIKE :q
       OR LOWER(automation_histories.error_message) LIKE :q
       OR LOWER(strategies.name) LIKE :q",
      q: q
    )
  }
end