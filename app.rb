class App < Sinatra::Base

    get '/' do
        redirect '/login'
    end

    get '/login' do
        slim :login
    end
    post '/login' do
        
    end

    get '/register' do
        slim :register
    end
    post '/register' do

    end

    get '/contacts' do
        slim :contacts
    end

end