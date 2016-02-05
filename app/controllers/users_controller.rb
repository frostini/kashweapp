require 'dotenv'
require 'httparty'
require 'dwolla'
require 'uri'

class UsersController < ApplicationController
  # before_action :logged_in_user, only: [:edit, :update]
  # before_action :correct_user, only: [:edit, :update]

  def index
    #greeting page
  end

  def show
    #user profile page that shows questions
    @user = User.find(params[:id])
    @last_contribution_group = Group.find(@user.last_contribution.group_id) unless @user.last_contribution.nil?
    @last_disbursement_group = Group.find(@user.last_disbursement.group_id) unless @user.last_disbursement.nil?
    @credit = @user.groups.where(group_type: "Credit")
    @savings = @user.groups.where(group_type: "Savings")
    @rando_interest_rate = rand(4..12)
  end

  def new
    #sign up form
    @user = User.new
  end

  def edit
    # update password/username form?
    @user = User.find(params[:id])
  end

  def create
    # create new user in database
    @user = User.new(user_params)
    if @user.save
      log_in @user
      redirect_to @user
    else
      render 'new'
    end
  end

  def update
    # update password or username?
    @user = User.find(params[:id])
    if @user.update_attributes(user_params)
      redirect_to @user
    else
      render 'edit'
    end
  end

  def destroy
    # delete user
    User.find(params[:id]).destroy
    redirect_to users_url
  end

  def make_payment
    # update user payment amount
    @user = User.find(params[:id])
    @group = Group.find(params[:group])
    @user.total_contribution += @group.payment_amount
    # update transaction
    Transaction.create(user_id: @user.id, group_id: @group.id, transaction_type: "debit", transaction_amount: @group.payment_amount)
    refresh_token(@user.id)
    @user.reload
    Dwolla::token = @user.dwolla_token
    Dwolla::Transactions.send({
      :destinationId => winner.dwolla_id,
      :amount => @group.payment_amount,
      :pin => @user.pin
    })
    @user.account_balance = Dwolla::Balance.get
    @user.save

    redirect_to @user
  end

  def oauth
    user = current_user
    Dwolla::api_key = ENV['DWOLLA_KEY']
    Dwolla::api_secret = ENV['DWOLLA_SECRET']
    Dwolla::sandbox = true
    if user.dwolla_token.nil?
      redirect_uri = "http://localhost:3000/users/#{user.id}/callback"
      authUrl = Dwolla::OAuth.get_auth_url(redirect_uri)
      redirect_to authUrl
    else
      redirect_to user
    end
  end

  def callback
    user = current_user
    authorization_code = params['code']
    redirect_uri = "http://localhost:3000/users/#{user.id}/callback"
    token_response = Dwolla::OAuth.get_token(authorization_code, redirect_uri)
    dwolla_token = token_response["access_token"]
    Dwolla::token = dwolla_token
    dwolla_refresh_token = token_response["refresh_token"]
    user_info = Dwolla::Users.get(user.email)
    user.dwolla_id = user_info['Id']
    user.dwolla_token = dwolla_token
    user.dwolla_refresh_token = dwolla_refresh_token
    # updating user's account balance
    user.account_balance = Dwolla::Balance.get
    user.save

    redirect_to user
  end

  def confirm_reserve
    @group = Group.find(params[:group_id])
    @user = current_user
    # need to make sure the user confirming is logged in
  end

  def deposit_reserve
    @group = Group.find(params[:group_id])
    pin = params[:dwolla_pin]
    user = current_user
    user.pin = pin
    user.save
    transaction = Transaction.create(user_id: user.id, group_id: @group.id, transaction_type: "reserve", transaction_amount: @group.payment_amount)
      # actually post the transactions on Dwolla
    refresh_token(user.id)
    user.reload
    Dwolla::token = user.dwolla_token
    Dwolla::Transactions.send({
      :destinationId => '812-740-4928',
      :amount => @group.payment_amount,
      :pin => pin
    })
    user.account_balance = Dwolla::Balance.get
    user.save
    redirect_to @group
  end

  private

  def user_params
    params.require(:user).permit(:first_name, :last_name, :email, :password, :password_digest)
  end

  def logged_in_user
    unless logged_in?
      redirect_to login_url
    end
  end

  def correct_user
    @user = User.find(params[:id])
    redirect_to(root_url) unless current_user?(@user)
  end

  def refresh_token(user_id)
    Dwolla::api_key = ENV['DWOLLA_KEY']
    Dwolla::api_secret = ENV['DWOLLA_SECRET']
    Dwolla::sandbox = true
    user = User.find(user_id)
    p user
    p user.dwolla_refresh_token
    token_response = Dwolla::OAuth.refresh_auth(user.dwolla_refresh_token)
    user.dwolla_token = token_response['access_token']
    user.dwolla_refresh_token = token_response['refresh_token']

    user.save
  end
end