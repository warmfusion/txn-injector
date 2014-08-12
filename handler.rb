require 'sinatra'
require 'json'

MAX_REQUEST_ARRAY_SIZE=500
requests = []

# Friendly home page :-)
get '/' do
  content_type :json  
  response = { "introduction" => "Tobys Trivial Txn Injector",
               "operations" => { "callback" => "%scallback" % request.url, 
                                 "teapot" => "%steapot" % request.url },
             }.to_json()
end


# The real callback handler that catches
# stores and returns a value encoded in the 
# data parameter
post '/callback' do
  unless params[:data].nil?
     body URI.unescape( params[:data] )
  else
     body "OK"
  end
 
  unless params[:status].nil?
    status params[:status]
  end

  guid = SecureRandom.uuid

  request.body.rewind
  requests << { 
		"id"       => params[:id],
		"guid"     => guid,
                "date"     => DateTime.now(),
                "request"  => {
                    "path"     => request.path_info,
                    "query"    => request.query_string,
                    "body"     => request.body.read  },
                    "request_env"  => request.env,
                "response" => { 
                    "body" => body, 
                    "status" => status, 
                    "headers" => headers },
                "_self"    => "%s/%s" % [request.url.split('?').first, guid],
                "_delete"    => "%s/%s/delete" % [request.url.split('?').first, guid]
              }

  # Pop the top off the requets lists if it gets too large :-)
  while requests.length > MAX_REQUEST_ARRAY_SIZE do
     requests.shift
  end 
     
end

# Returns all the recieved callback events so far
get '/callback/?' do
  content_type :json
  size=10
  from = params[:page].nil? ? 1 : params[:page].to_i

  visible_requests = requests

  # Allow users to filter by incoming id value using ?id=1235
  unless params[:id].nil?
    visible_requests.select! { |r| r["id"] == params[:id] }
  end

  # Allow users to filter by path using ?path=/callback
  unless params[:path].nil?
    visible_requests.select! { |r| r["request"]["path"] == params[:path] }
  end

  response = { 
               "operations" => { "clear" => "%s/clear" % request.url.split('?').first },
               "pagination" => { "page" => from, 
                                 "page_size" => size ,
                                 "page_count" => ((visible_requests.length / size).floor() +1), 
                                 "total_requests" => visible_requests.length ,
                                },
               "requests" => visible_requests.reverse.slice((from -1) * size ,size)
             }.to_json()
end

 
# Remove all the callbacks in one go
#  - useful to clear up after bigger testing
get '/callback/clear' do
  requests = []
  content_type :json
  { :request => "cleared" }.to_json()
end



# View a callback in isolation
#  - useful for sharing callback events with others
get '/callback/:id' do |id|
  content_type :json
  callback_request = requests.select { |r| r["guid"] == id }

  body = callback_request.to_json()
end

# Remove a callback event from the array
# - useful for tidying up after testing
get '/callback/:id/delete' do |id|
  content_type :json
  requests.delete_if{ |request| request["guid"] == id }

  body = "OK".to_json
end



# Teapot
get '/teapot' do
  status 418
  headers \
    "Allow"   => "BREW, POST, GET, PROPFIND, WHEN",
    "Refresh" => "Refresh: 3; http://www.ietf.org/rfc/rfc2324.txt"
  body "I'm a tea pot!"
end




set(:method) do |method|
  method = method.to_s.upcase
  condition { request.request_method == method }
end

before :method => :post do
  puts "pre-process POST"
end 

after :method => :post do
  puts "post-process POST"
end
