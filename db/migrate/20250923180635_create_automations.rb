class CreateAutomations < ActiveRecord::Migration[7.1]
  def change
    create_table :automations do |t|
      t.references :template, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.string :status, null: false, default: 'scheduled'
      t.datetime :send_at, null: false
      t.boolean :enabled, null: false, default: true

      t.jsonb :action_data, null: false
      t.text :error_message

      t.timestamps
    end
    add_index :automations, :status
    add_index :automations, :send_at
    add_index :automations, :enabled
  end
end
