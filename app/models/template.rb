class Template < ApplicationRecord
    # --- Associations ---
    belongs_to :user
    has_many :automations, dependent: :destroy

    # --- Validations ---
    validates :name, presence: true
    validates :spreadsheet_url, presence: true, on: :update # URL is not known at initial creation

    # --- Store Accessors for JSONB ---
    # This makes it easy to access nested data in the `rules_data` column
    # as if they were actual columns on the model.
    store_accessor :rules_data, :columns, :rules
end
