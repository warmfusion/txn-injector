require 'sinatra'
require 'json'

requests = []

post '/callback' do
  URI.unescape( params[:data] )
  requests << request
end

get '/' do
  "Please post your query to /callback?data=someValue "
end

get '/callback' do
  requests.to_json()
end


get '/callback/clear' do
  requests = []
  "Request array cleared"
end
