class AddDwollaIdToUsers < ActiveRecord::Migration
  def change
    add_column :users, :dwolla_id, :string
  end
end
