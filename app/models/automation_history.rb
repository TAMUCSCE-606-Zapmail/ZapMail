# app/models/automation_history.rb
class AutomationHistory < ApplicationRecord
  belongs_to :automation

  scope :search, ->(query) {
  return all if query.blank?

  q = "%#{query.downcase}%"
  adapter = connection.adapter_name.downcase.to_sym

  email_expr =
    if adapter == :postgresql
      "LOWER(automation_histories.row_data ->> 'email')"
    else
      "LOWER(json_extract(automation_histories.row_data, '$.email'))"
    end

  joins(automation: :strategy).where(
    "#{email_expr} LIKE :q
     OR LOWER(automation_histories.api_response) LIKE :q
     OR LOWER(automation_histories.error_message) LIKE :q
     OR LOWER(strategies.name) LIKE :q",
    q: q
  )
}
end