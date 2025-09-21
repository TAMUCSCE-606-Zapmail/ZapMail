class CreateConditions < ActiveRecord::Migration[8.0]
  def change
    create_table :conditions do |t|
      t.references :rule, null: false, foreign_key: true
      t.string :column_name
      t.string :operator
      t.string :value

      t.timestamps
    end
  end
end
