class CreateStrategyActions < ActiveRecord::Migration[8.0]
  def change
    create_table :strategy_actions do |t|
      t.references :rule, null: false, foreign_key: true
      t.string :action_type
      t.text :prompt_template

      t.timestamps
    end
  end
end
