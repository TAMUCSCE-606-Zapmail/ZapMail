class CreateTemplates < ActiveRecord::Migration[7.1]
  def change
    create_table :templates do |t|
      t.string :name, null: false
      t.string :spreadsheet_url
      t.jsonb :rules_data, default: {} # Stores columns, rules, actions, etc.
      t.references :user, null: false, foreign_key: true # Assumes you have a User model

      t.timestamps # Adds created_at and updated_at
    end
  end
end
