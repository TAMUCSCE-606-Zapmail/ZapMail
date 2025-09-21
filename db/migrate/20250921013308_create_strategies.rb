class CreateStrategies < ActiveRecord::Migration[8.0]
  def change
    create_table :strategies do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name
      t.string :csv_file_path

      t.timestamps
    end
  end
end
