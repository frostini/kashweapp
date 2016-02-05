class CreateTransactions < ActiveRecord::Migration
  def change
    create_table :transactions do |t|
      t.belongs_to :user
      t.references :group
      t.string :transaction_type
      t.integer :transaction_amount

      t.timestamps null: false
    end
  end
end
