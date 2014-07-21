require 'rspec'

class User
  def initialize(name, role, *accounts)
    @name = name
    @role = role
    @accounts = accounts
    @accounts.each { |a| a.add_member(self) } #unless accounts.nil?
  end

  def can_view?(current_account)
    @accounts.include?(current_account)
  end

  def can_be_edit_by(user)
    if user != self && @role != :owner && !user.is_member?
        return true
    end
    false
  end

  def is_member?
    @role == :member
  end

  def is_owner?
    @role == :owner
  end

  def to_s
    "#{@name} | #{@role}"
  end
end

class Account
  def initialize
    @id = rand(1000)
    @users = []
    @has_owner = false
  end

  def add_member(member)
    if member.is_owner? && @has_owner
      raise ArgumentError, "Account already has owner."
    end
    @has_owner = true if member.is_owner?
    @users << member
  end

  def print_users_for(user, output)
    @users.each do |u|
      output << u.to_s
      if u.can_be_edit_by(user)
        output << " | x\n"
      else
        output << "\n"
      end
    end
  end
end

class MembersController
  def index # GET /accounts/123/members
    unless current_user.can_view?(current_account)
      flash[:error] = "You shall not pass!"
      redirect 'new'
    end
    output = ''
    current_account.print_users_for(current_user, output)
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
    user = User.new("pacho", :admin, account)
    expect(user.can_view?(account)).to eq true
  end

  it 'cant view account members' do
    account = Account.new
    user = User.new('prd', :member)
    expect(user.can_view?(account)).to eq false
  end

  it 'can be member of 2 accounts' do
    account1 = Account.new
    account2 = Account.new
    account3 = Account.new
    user = User.new("janosik", :member, account1, account2)
    expect(user.can_view?(account1)).to eq true
    expect(user.can_view?(account2)).to eq true
    expect(user.can_view?(account3)).to eq false
  end
  #
  # it 'user has name and role' do
  #   account = Account.new
  #   user1 = User.new("Peto", :owner, account)
  #   user2 = User.new("Jozef", :admin, account)
  #
  #   expect(user1.name).to eq "Peto"
  #   expect(user1.role).to eq :owner
  #   expect(user2.name).to eq "Jozef"
  #   expect(user2.role).to eq :admin
  # end


  it 'print group of users of current account' do
    account = Account.new
    user1 = User.new("Peto", :owner, account)
    user2 = User.new("Jozo", :admin, account)
    user3 = User.new("Jano", :member, account)
    user4= User.new("Fero", :member, account)

    expected_output = "Peto | owner\n" +
        "Jozo | admin | x\n" +
        "Jano | member | x\n" +
        "Fero | member | x\n"
    output = ''
    account.print_users_for(user1, output)
    expect(output).to eq expected_output

    expected_output = "Peto | owner\n" +
        "Jozo | admin\n" +
        "Jano | member\n" +
        "Fero | member\n"
    output = ''
    account.print_users_for(user3, output)
    expect(output).to eq expected_output
  end

  it 'can_be_edit_by works properly' do
    account = Account.new
    user1 = User.new("Peto", :owner, account)
    user2 = User.new("Jozo", :admin, account)
    user3 = User.new("Jano", :member, account)
    user4 = User.new("Fero", :member, account)

    expect(user1.can_be_edit_by(user2)).to eq false
    expect(user1.can_be_edit_by(user3)).to eq false
    expect(user2.can_be_edit_by(user2)).to eq false
    expect(user3.can_be_edit_by(user2)).to eq true
    expect(user3.can_be_edit_by(user4)).to eq false
  end

  it 'account can have only one owner' do
    account = Account.new
    user1 = User.new("Peto", :owner, account)
    expect { User.new("Jozo", :owner, account) }.to raise_error(ArgumentError)
  end
end


# TODO vyriesit generovanie id v Account