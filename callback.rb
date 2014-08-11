require 'sinatra'
require 'json'

MAX_REQUEST_ARRAY_SIZE=500
requests = []

post '/callback' do
  request.body.rewind
  requests << { 
                "body"  => request.body.read, 
                "path"  => request.path_info,
                "query" => request.query_string,
                "date"  => DateTime.now()
              }

  # Pop the top off the requets lists if it gets too large :-)
  while requests.length > MAX_REQUEST_ARRAY_SIZE do
     requests.shift
  end 
     
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
  size=10
  from = params[:page].nil? ? 1 : params[:page].to_i

  response = { 
               "operations" => { "clear" => "%s/clear" % request.url },
               "pagination" => { "page" => from, 
                                 "page_size" => size ,
                                 "page_count" => ((requests.length / size).floor() +1), 
                                 "total_requests" => requests.length ,
                                },
               "requests" => requests.reverse.slice((from -1) * size ,size)
             }.to_json()
end


get '/callback/clear' do
  requests = []
  content_type :json
  { :request => "cleared" }.to_json()
end
