class App < Sinatra::Base

    enable :sessions
    
    before do 
        @database = SQLite3::Database.open("./db/database.sqlite")
        @user = nil
        if session['username'] != nil
            @user = @database.execute('SELECT * FROM users WHERE username IS ?', session['username']).first
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
            if user_data[2] == params['password']
                session['username'] = params['username']
                redirect '/contacts'
            end
        else
            @error = "User does not exist."
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
                    params['username'], params['password'], params['email'])
                redirect '/login'
            else
                puts user_data[1]
                if user_data[3] == params['email']
                    @error = "Email already in use."
                elsif user_data[1] == params['username']
                    @error = 'Username already in use.'
                end 
            end
        else
            @error = "Passwords do not match."
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