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
            @database.execute('DELETE FROM contact_socialgroups WHERE socialgroup_id IS ?', params['id'])
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

        if params['name'] == ""
            @error = 'Please enter a contact name.'
            @socialgroups = @database.execute('SELECT * FROM socialgroups WHERE user_id IS ?', @user[0])
            slim :'contacts/add'
        else
            @database.execute('INSERT INTO contacts(user_id, name, email, number) VALUES (?, ?, ?, ?)', @user[0], params['name'], params['email'], params['number'])
            contact_id = @database.execute("SELECT last_insert_rowid()").first.first
            socialgroup_ids = []
            params.each do |s,v|
                if s.start_with? "socialgroup"
                    sg_id = s.split("_")[1].to_i
                    socialgroup_ids.push(sg_id)
                end
            end
            Utils.add_socialgroups(@database, socialgroup_ids, contact_id, @user)
            redirect '/contacts'
        end
    end

    get '/contacts/:id' do
        if !@user
            redirect '/login'
        end

        @contact = @database.execute("SELECT * FROM contacts WHERE id IS ? AND user_id IS ?", params[:id], @user[0]).first
        @socialgroups = @database.execute('SELECT * FROM socialgroups WHERE user_id IS ?', @user[0])
        @checked_groups = @database.execute("SELECT * FROM contact_socialgroups WHERE contact_id IS ?", params[:id]).map {|s| s[1].to_i}

        if !@contact
            redirect '/contacts'
        end
        slim :'contacts/edit'
    end
    post '/contacts/:id' do
        if !@user
            redirect '/login'
        end

        if params['name'] == ""
            @error = 'Please enter a contact name.'

            @contact = @database.execute("SELECT * FROM contacts WHERE id IS ? AND user_id IS ?", params[:id], @user[0]).first
            @socialgroups = @database.execute('SELECT * FROM socialgroups WHERE user_id IS ?', @user[0])
            @checked_groups = @database.execute("SELECT * FROM contact_socialgroups WHERE contact_id IS ?", params[:id]).map {|s| s[1].to_i}

            slim :'contacts/edit'
        else
            @database.execute('UPDATE contacts SET name = ?, email = ?, number = ? WHERE user_id IS ? AND id IS ?',params['name'], params['email'], params['number'], @user[0], params[:id])
            @database.execute('DELETE FROM contact_socialgroups WHERE contact_id IS (SELECT id FROM contacts WHERE user_id IS ? AND id IS ?)', @user[0], params[:id])
            contact_id = params[:id]
            socialgroup_ids = []
            params.each do |s,v|
                if s.start_with? "socialgroup"
                    sg_id = s.split("_")[1].to_i
                    socialgroup_ids.push(sg_id)
                end
            end
            Utils.add_socialgroups(@database, socialgroup_ids, contact_id, @user)
            redirect '/contacts'
        end
    end
    post '/contacts/delete/:id' do
        if !@user
            redirect '/login'
        end

        @database.execute('DELETE FROM contact_socialgroups WHERE contact_id IN (SELECT id FROM contacts WHERE user_id IS ? AND id IS ?)', @user[0], params[:id] )
        @database.execute('DELETE FROM contacts WHERE id IS ? AND user_id IS ?', params[:id], @user[0])

        redirect '/contacts'
    end

    get '/contacts' do
        if !@user
            redirect '/login'
        end

        @contacts = @database.execute('SELECT * FROM contacts WHERE user_id IS ?', @user[0])
        @contacts.map { |c| c.push(@database.execute("SELECT * FROM socialgroups WHERE id IN (SELECT socialgroup_id FROM contact_socialgroups WHERE contact_id IS #{c[0]})")) }
        slim :contacts
    end

    get '/logout' do
        session.clear
        redirect '/'
    end

end
