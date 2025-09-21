class CreateAutomationHistories < ActiveRecord::Migration[8.0]
  def change
    create_table :automation_histories do |t|
      t.references :automation, null: false, foreign_key: true
      t.json :row_data
      t.string :email_status
      t.text :api_response
      t.text :error_message

      t.timestamps
    end
  end
end
