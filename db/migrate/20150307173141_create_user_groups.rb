class CreateUserGroups < ActiveRecord::Migration
  def change
    create_table :user_groups do |t|
      t.belongs_to :user
      t.belongs_to :group
      t.boolean :paid

      t.timestamps null: false
    end
  end
end
