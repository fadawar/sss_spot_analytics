require 'rspec'

class User
  def initialize(*accounts)
    @accounts = accounts
    @accounts.each { |a| a.add_member(self) } #unless accounts.nil?
  end

  def can_view?(current_account)
    @accounts.include?(current_account)
  end
end

class Account
  def initialize
    @id = rand(1000)
    @members = []
  end

  def add_member(member)
    @members << member
  end
end

class MembersController
  def index # GET /accounts/123/members
    unless current_user.can_view?(current_account)
      flash[:error] = "You shall not pass!"
      redirect 'new'
    end
    current_account.members do |m|
      puts m.role
    end
  end

  def current_user
    User.find(cookies[:id])
  end

  def current_account
    Account.find(params[:account_id])
  end
end

RSpec.describe User do
  it 'can view account members' do
    account = Account.new
    user = User.new(account)
    expect(user.can_view?(account)).to eq true
  end

  it 'cant view account members' do
    account = Account.new
    user = User.new
    expect(user.can_view?(account)).to eq false
  end

  it 'can be member of 2 accounts' do
    account1 = Account.new
    account2 = Account.new
    account3 = Account.new
    user = User.new(account1, account2)
    expect(user.can_view?(account1)).to eq true
    expect(user.can_view?(account2)).to eq true
    expect(user.can_view?(account3)).to eq false
  end
end


# TODO vyriesit generovanie id v Account