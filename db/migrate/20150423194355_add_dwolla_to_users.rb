class AddDwollaToUsers < ActiveRecord::Migration
  def change
    add_column :users, :dwolla_token, :string
    add_column :users, :dwolla_refresh_token, :string
  end
end
