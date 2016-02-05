class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :first_name
      t.string :last_name
      t.string :email
      t.string :password_digest
      t.string :account_name
      t.integer :account_balance
      t.integer :account_number
      t.integer :total_contribution, default: 0
      t.integer :total_received, default: 0

      t.timestamps null: false
    end
  end
end
