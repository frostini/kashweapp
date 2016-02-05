class RemoveUnusefulAccountInfoFromUsers < ActiveRecord::Migration
  def change
    remove_column :users, :account_number, :integer
    remove_column :users, :account_name, :string
  end
end
