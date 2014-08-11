require 'sinatra'
require 'json'

requests = []

post '/callback' do
  request.body.rewind
  requests << { "body"  => request.body.read, 
                "path"  => request.path_info,
                "query" => request.query_string
              }
  URI.unescape( params[:data] )
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
