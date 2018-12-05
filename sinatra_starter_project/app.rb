require "sinatra"
require 'sinatra/flash'
require_relative "authentication.rb"
require 'stripe'

set :publishable_key, 'pk_test_TYooMQauvdEDq54NiTphI7jx'
#ENV['PUBLISHABLE_KEY']
set :secret_key, 'sk_test_4eC39HqLyjWDarjtT1zdp7dc'
#ENV['SECRET_KEY']

Stripe.api_key = settings.secret_key

if ENV['DATABASE_URL']
  DataMapper::setup(:default, ENV['DATABASE_URL'] || 'postgres://localhost/mydb')
else
  DataMapper::setup(:default, "sqlite3://#{Dir.pwd}/app.db")
end

#make an admin user if one doesn't exist!
if User.all(administrator: true).count == 0
	u = User.new
	u.email = "admin@admin.com"
	u.password = "admin"
	u.administrator = true
	u.save
end


#the following urls are included in authentication.rb
# GET /login
# GET /logout
# GET /sign_up

# authenticate! will make sure that the user is signed in, if they are not they will be redirected to the login page
# if the user is signed in, current_user will refer to the signed in user object.
# if they are not signed in, current_user will be nil

get "/" do
	erb :index
end


get "/dashboard" do
	authenticate!
	erb :dashboard
end

get "/upgrade" do
	authenticate!
	erb :upgradeForm
end

get "/aboutUs" do	
	erb :aboutUs 
end

get "/profile" do
	authenticate!
	if current_user.pro
		@birthdays = Birthday.all(user_id: current_user.id)
		erb :profile
	end
end

get "/saveBirthdate" do
	erb :saveBirthdateForm
end

get "/gallery" do
	erb :gallerypics 
end

post "/birthdate/create" do
	authenticate!
	if current_user.pro
		if params["firstName"] && params["lastName"] && params["relationship"] && params["birthdate"] 
			b = Birthday.new
			b.first_name = params["firstName"]
			b.last_name = params["lastName"]			
			b.birthdate = params["birthdate"]
			b.relationship = params["relationship"]
			b.user_id = current_user.id			
			b.save
			redirect "/profile"
		end
	else
		redirect "/"
	end
end






post '/charge' do
  current_user.pro = true
  current_user.save
  # Amount in cents
  @amount = 500

  customer = Stripe::Customer.create(
    :email => 'customer@example.com',
    :source  => params[:stripeToken]
  )

  charge = Stripe::Charge.create(
    :amount      => @amount,
    :description => 'Sinatra Charge',
    :currency    => 'usd',
    :customer    => customer.id
  )

  erb :charge  
end

error Stripe::CardError do
  env['sinatra.error'].message
end