require 'sinatra'

post '/callback' do
  URI.unescape( params[:data] )
end

get '/' do
  "Please post your query to /callback?data=someValue "
end
