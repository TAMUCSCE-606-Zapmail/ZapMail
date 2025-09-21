class CreateAutomations < ActiveRecord::Migration[8.0]
  def change
    create_table :automations do |t|
      t.references :strategy, null: false, foreign_key: true
      t.string :status
      t.datetime :next_run_time
      t.string :schedule_type
      t.datetime :end_time

      t.timestamps
    end
  end
end
