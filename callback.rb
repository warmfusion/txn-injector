require 'sinatra'
require 'json'

requests = []

post '/callback' do
  request.body.rewind
  requests << { 
                "body"  => request.body.read, 
                "path"  => request.path_info,
                "query" => request.query_string
              }
  unless params[:data].nil?
     body URI.unescape( params[:data] )
  else
     body "OK"
  end
end

get '/' do
  "Please post your query to /callback?data=someValue "
end

get '/callback' do
  content_type :json
  response = { 
               "operations" => { "clear" => "%s/clear" % request.url },
               "requests" => requests
             }.to_json()
end


get '/callback/clear' do
  requests = []
  content_type :json
  { :request => "cleared" }.to_json()
end
