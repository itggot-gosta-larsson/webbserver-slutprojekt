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

    #socialgroups
    get '/socialgroups' do
        if !@user
            redirect '/login'
        end
        @socialgroups = @database.execute('SELECT * FROM socialgroups WHERE user_id IS ?', @user[0])
        slim :socialgroups
    end
    post '/socialgroups/add' do
        if !@user
            redirect '/login'
        end
        result = @database.execute('SELECT * FROM socialgroups WHERE user_id IS ? AND name IS ?', @user[0], params['name'])
        if result.first == nil
            @database.execute('INSERT INTO socialgroups(user_id, name) VALUES (?,?)', @user[0], params['name'])
        end
        redirect '/socialgroups'
    end
    post '/socialgroups/delete/:id' do
        if !@user
            redirect '/login'
        end
        result = @database.execute('SELECT * FROM socialgroups WHERE user_id IS ? AND id IS ?', @user[0], params['id'])
        if result.first != nil
            @database.execute('DELETE FROM socialgroups WHERE id IS ?', params['id'])
        end
        redirect '/socialgroups'
    end

    #contacts

    get '/contacts/add' do
        if !@user
            redirect '/login'
        end

        @socialgroups = @database.execute('SELECT * FROM socialgroups WHERE user_id IS ?', @user[0])

        slim :'contacts/add'
    end
    post '/contacts/add' do
        if !@user
            redirect '/login'
        end

        @database.execute('INSERT INTO contacts(user_id, name, email, number) VALUES (?, ?, ?, ?)', @user[0], params['name'], params['email'], params['number'])
        socialgroups = []
        params.each do |s,v|
            if s.start_with? "socialgroup"
                n = s.split("_")[1].to_i
                socialgroups += [n]
            end
        end
        test_statement = ""
        socialgroups.each do |s|
            if test_statement != ""
                test_statement += " OR "                
            end
            test_statement += "id IS #{s}"
        end
        confirmed_socialgroups = @database.execute('SELECT * FROM socialgroups WHERE user_id IS ? AND (?)', @user[0], test_statement)
        puts "SELECT * FROM socialgroups WHERE user_id IS #{@user[0]} AND (#{test_statement})"
        puts confirmed_socialgroups
        redirect '/contacts'
    end

    get '/contacts/:id' do
        if !@user
            redirect '/login'
        end

        @contact_id = params[:id]

        slim :'contacts/view'
    end

    get '/contacts' do
        if !@user
            redirect '/login'
        end

        @contacts = @database.execute('SELECT * FROM contacts WHERE user_id IS ?', @user[0])

        slim :contacts
    end

end
