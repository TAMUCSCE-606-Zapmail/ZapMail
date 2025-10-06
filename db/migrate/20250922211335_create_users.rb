class CreateUsers < ActiveRecord::Migration[7.1]
  def change
    create_table :users do |t|
      t.string :name, null: false
      t.string :email, null: false
      t.string :password_digest, null: false
      t.date :date_of_birth
      t.string :major
      t.string :classification
      t.string :uin

      t.timestamps
    end
    add_index :users, :email, unique: true
    add_index :users, :uin, unique: true
  end
end
