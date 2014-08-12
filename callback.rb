require 'sinatra'
require 'json'

MAX_REQUEST_ARRAY_SIZE=500
requests = {}
requests[:callback] = []
requests[:notify]   = []

get '/' do
  content_type :json  
  response = { "introduction" => "Tobys Trivial Txn Injector",
               "operations" => { "callback" => "%scallback" % request.url,
                                 "notify" => "%snotify" % request.url },
             }.to_json()
end


# CALLBACK HANDLERS
post '/callback' do
  request.body.rewind
  requests[:callback] << { 
                "body"  => request.body.read, 
                "path"  => request.path_info,
                "query" => request.query_string,
                "date"  => DateTime.now()
              }

  # Pop the top off the requets lists if it gets too large :-)
  while requests[:callback].length > MAX_REQUEST_ARRAY_SIZE do
     requests[:callback].shift
  end 
     
  unless params[:data].nil?
     body URI.unescape( params[:data] )
  else
     body "OK"
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
               "requests" => requests[:callback].reverse.slice((from -1) * size ,size)
             }.to_json()
end

get '/callback/clear' do
  requests = []
  content_type :json
  { :request => "cleared" }.to_json()
end


#

# NOTIFY HANDLERS
post '/notify' do
  request.body.rewind
  requests[:notify] << { 
                "body"  => request.body.read, 
                "path"  => request.path_info,
                "query" => request.query_string,
                "date"  => DateTime.now()
              }

  # Pop the top off the requets lists if it gets too large :-)
  while requests[:notify].length > MAX_REQUEST_ARRAY_SIZE do
     requests[:notify].shift
  end 
     
  body "OK"
end

get '/notify' do
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
               "requests" => requests[:notify].reverse.slice((from -1) * size ,size)
             }.to_json()
end

get '/notify/clear' do
  requests[:notify] = []
  content_type :json
  { :request => "cleared" }.to_json()
end

