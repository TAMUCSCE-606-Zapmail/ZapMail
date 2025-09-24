class CreateRules < ActiveRecord::Migration[8.0]
  def change
    create_table :rules do |t|
      t.references :strategy, null: false, foreign_key: true
      t.integer :order

      t.timestamps
    end
  end
end
