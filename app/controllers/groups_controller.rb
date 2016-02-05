class GroupsController < ApplicationController
  def new
    @group = Group.new
  end

  def create
    @group = Group.new(group_params)
    if @group.save
      @group.update(disbursement_date: @group.payment_date + 25)
      render 'new_members'
    else
      render 'new'
    end
  end

# GET request to the form page to add new members to the group
  def new_members
    @group = Group.find(params[:id])
  end

# POST request to add the members to the group
  def add_members
    @group = Group.find(params[:id])
    params.keys.each do |key|
      if key.include?('member')
        UserGroup.create(group_id: @group.id, user_id: User.find_by(email: params[key]).id, paid: false)
      end
    end
    @group.update(disbursement_amount: @group.users.count * @group.payment_amount)
    # only redirect to pay reserve if it is a savings group
    if @group.group_type == "Savings"
      redirect_to "/users/#{current_user.id}/confirmgroup?group_id=#{@group.id}"
    else
      redirect_to @group
    end
  end

  def show
    @group = Group.find(params[:id])
  end

  def distribution
    @group = Group.find(params[:id])
    unpaid_users = []
    @group.users.each {|user| unpaid_users << user if !user.paid?(@group.id)}
    winner = unpaid_users.sample
    Transaction.create(user_id: winner.id, group_id: @group.id, transaction_type: "credit", transaction_amount: @group.disbursement_amount)
    refresh_master_token
    master_account = User.find_by(email: "master@mail.com")
    Dwolla::token = master_account.dwolla_token
    Dwolla::sandbox = true
    Dwolla::Transactions.send({
      :destinationId => winner.dwolla_id,
      :amount => @group.disbursement_amount,
      :pin => master_account.pin
    })
    master_account.account_balance = Dwolla::Balance.get
    master_account.save

    redirect_to @group
  end

  private

  def group_params
    params.require(:group).permit(:name, :group_type, :payment_date, :payment_amount, :member1, :member2, :member3, :member4, :member5, :member6, :member7, :member8, :member9, :member10, :member11, :member12,)
  end

  def refresh_master_token
    Dwolla::api_key = ENV['DWOLLA_KEY']
    Dwolla::api_secret = ENV['DWOLLA_SECRET']
    Dwolla::sandbox = true
    user = User.find_by(email: "master@mail.com")
    token_response = Dwolla::OAuth.refresh_auth(user.dwolla_refresh_token)
    user.dwolla_token = token_response['access_token']
    user.dwolla_refresh_token = token_response['refresh_token']

    user.save
  end

end
