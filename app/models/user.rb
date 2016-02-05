class User < ActiveRecord::Base
  has_many :user_groups
  has_many :groups, through: :user_groups
  has_many :transactions

  # write user validations and password hash shit here
  validates :first_name, :presence => true
  validates :last_name, :presence => true
  validates :email,    :presence => true,
                       :uniqueness => true,
                       :format => { :with => /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i }
  has_secure_password
  validates :password, length: { minimum: 6 }, allow_blank: true

  def paid?(group_id)
    return UserGroup.find_by(user_id: self.id, group_id: group_id).paid
  end

  def last_contribution
    return self.transactions.where(transaction_type: "debit").last
  end

  def last_disbursement
    return self.transactions.where(transaction_type: "credit").last
  end
end
