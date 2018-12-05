require 'data_mapper' # metagem, requires common plugins too.

# need install dm-sqlite-adapter
# if on heroku, use Postgres database
# if not use sqlite3 database I gave you
if ENV['DATABASE_URL']
  DataMapper::setup(:default, ENV['DATABASE_URL'] || 'postgres://localhost/mydb')
else
  DataMapper::setup(:default, "sqlite3://#{Dir.pwd}/app.db")
end

class User
    include DataMapper::Resource
    property :id, Serial
    property :email, String
    property :password, String
    property :created_at, DateTime
    property :pro, Boolean, :default => false
    property :administrator, Boolean, :default => false
    #property :roleID, Integer, :default => 0

    # def admin?
    #     return roleID == 2
    # end

    # def pro?
    #     return roleID == 1
    # end

    # def free?
    #     return roleID == 0
    # end

    def birthdays
        return Birthday.all(user_id: id)
    end

    def login(password)
    	return self.password == password
    end
end


class Birthday
    include DataMapper::Resource
    property :id, Serial
    property :user_id, Integer
    property :first_name, String
    property :last_name, String
    property :relationship, String
    property :birthdate, String

    def user
        @user ||= User.get(user_id)
        return @user
    end
end


# Perform basic sanity checks and initialize all relationships
# Call this when you've defined all your models
DataMapper.finalize

# automatically create the post table
User.auto_upgrade!
Birthday.auto_upgrade!
