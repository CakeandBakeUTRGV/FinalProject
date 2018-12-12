require "sinatra"
require 'sinatra/flash'
require_relative "authentication.rb"
require 'stripe'
require 'twilio-ruby'
require 'openssl'
OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE


account_sid = "AC00a5f5404412b181c55250291a825353" 
auth_token = "c9c7d2eccbcca4399d13bd354045af0e" 

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
	if current_user.administrator
		erb :dashboard
	else
		redirect "/"
	end
end  

get "/upgrade" do
	authenticate!
	if current_user.pro
		redirect "/"
	else
		erb :upgradeForm
	end
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
	authenticate!
	if current_user.pro
		erb :saveBirthdateForm
	else
		redirect "/"
	end
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

			number_to_text = "+1" + current_user.phone_number
			@client = Twilio::REST::Client.new(account_sid, auth_token)
			message = @client.messages.create(				
			    body: "You created a birthdate for #{b.first_name} #{b.last_name}! You will be reminded near the date.",
			    to: "+18329935855", # Replace with your phone number
			    #to: number_to_text,    
			    from: "+15753005987")  # Replace with your Twilio number
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