class App < Sinatra::Base

    enable :sessions
    
    before do 
        @database = SQLite3::Database.open("./db/database.sqlite")
        @user = nil
        if session['user_id']
            @user = @database.execute('SELECT * FROM users WHERE id IS ?', session['user_id']).first
        end
    end

    get '/' do
        if @user
            redirect '/contacts'
        else
            redirect '/login'
        end
    end

    get '/login' do
        slim :login
    end
    post '/login' do
        @error = ""
        user_data = @database.execute('SELECT * FROM users WHERE username IS ?', params['username']).first
        if user_data
            if BCrypt::Password.new(user_data[2]) == params['password']
                session['user_id'] = user_data[0]
                redirect '/contacts'
            else
                @error = "Invalid password."
            end
        else
            @error = "Invalid username."
        end
        slim :login
    end

    get '/register' do
        slim :register
    end
    post '/register' do
        @error = ""
        if params['password_conf'] == params['password']
            user_data = @database.execute('SELECT * FROM users WHERE username IS ? OR email IS ?', params['username'], params['email']).first
            if !user_data
                @database.execute('INSERT INTO users(username, password, email) VALUES (?, ?, ?)', 
                    params['username'], BCrypt::Password.create(params['password']), params['email'])
                redirect '/login'
            else
                if user_data[3] == params['email']
                    @error = "Email already in use."
                elsif user_data[1] == params['username']
                    @error = 'Username already in use.'
                end 
            end
        else
            @error = "Passwords do not match." #Fråga att tänka på: svenska eller engelska?
        end
        slim :register
    end

    get '/contacts' do
        if !@user
            redirect '/login'
        end
        slim :contacts
    end

end
