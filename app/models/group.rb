class Group < ActiveRecord::Base
  has_many :user_groups
  has_many :users, through: :user_groups

  def rounds_occured
    rounds_occured = 0
    self.users.each do |user|
      rounds_occured += 1 if user.paid?(self.id) == true
    end
    rounds_occured
  end

  def rounds_remaining
    rounds_occured = 0
    self.users.each do |user|
      rounds_occured += 1 if user.paid?(self.id) == true
    end
    return rounds_remaining = self.users.count - rounds_occured
  end

end
