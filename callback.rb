require 'sinatra'
require 'json'

MAX_REQUEST_ARRAY_SIZE=500
requests = []

get '/' do
  content_type :json  
  response = { "introduction" => "Tobys Trivial Txn Injector",
               "operations" => { "callback" => "%scallback" % request.url },
             }.to_json()
end


# CALLBACK HANDLERS
post '/callback' do
  unless params[:data].nil?
     body URI.unescape( params[:data] )
  else
     body "OK"
  end


  request.body.rewind
  requests << { 
		"id"       => params[:id],
                "date"     => DateTime.now(),
                "path"     => request.path_info,
                "query"    => request.query_string,
                "body"     => request.body.read, 
                "response" => body
              }

  # Pop the top off the requets lists if it gets too large :-)
  while requests.length > MAX_REQUEST_ARRAY_SIZE do
     requests.shift
  end 
     
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


