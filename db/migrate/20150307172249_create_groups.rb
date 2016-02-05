class CreateGroups < ActiveRecord::Migration
  def change
    create_table :groups do |t|
      t.string :name
      t.string :group_type
      t.date :payment_date
      t.integer :payment_amount
      t.integer :disbursement_amount
      t.date :disbursement_date

      t.timestamps null: false
    end
  end
end
