require 'sinatra'
require 'docdsl'
require 'json'

# Online Documentation!
register Sinatra::DocDsl

page do
  title "Callback Documentation"
  header "The Simple Callback Handler"
  introduction "This is a trivial implementation of the txn-injectors callback functionality \
      written to work on heroku"
end

MAX_REQUEST_ARRAY_SIZE=500
requests = []

stateful_requests = {}

documentation "Go look at /docs" do
  response "Redirects to the documentation"
  status 303
end
get '/' do
  redirect "/doc"
end


documentation "Post a callback and get a response.

The status parameter accepts a comma separated list of status codes which are used
in sequence for each incoming request - This allows you to setup a retry chain without
changing the url in the application. For example, ```status=404,403,200``` would return
each of those codes in sequence, and will repeat the last status" do
  query_param :id, "A useful Identifier (optional) that can be used to track requests"
  query_param :data, "The data to return in the callback response, default 'OK'"
  query_param :status, "A http status code to use on the response, default 200"
  payload "Any content at all"
end
post '/callback' do
  unless params[:data].nil?
     body URI.unescape( params[:data] )
  else
     body "OK"
  end
 
  # Decide which status code to return  
  unless params[:status].nil?                              # If the user has included a status code..
    status_codes = params[:status].split(',')              # They can include multiple comma separated values, eg 404,403,303,200
    if status_codes.length == 1                             # but if only one is provided
        status params[:status]                             #   simply return it as the status
    else                                                   # But if more than one status code exists
        if stateful_requests.has_key?( params[:id] )       #   and we've seen this request before
            state_index = stateful_requests[params[:id]]   #     Then get the status index
        else                                               #   otherwise...
            state_index = 0                                #      The index starts at 0
        end                                                #   and...
        if state_index < status_codes.length               #   if the index is lower than the number of status' provided
           status status_codes[state_index].to_i         #      the status is returned from the index
        else                                               #   otherwise                
           status status_codes.last.to_i                 #      Just return the last status on the list
        end                                                #   and...
        state_index = state_index+1                        #   increment the index
        stateful_requests[params[:id]] = state_index       #   and store it for future callback attempts        
    end
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


documentation "Get a list of the recently submitted callback requests and responses. Supports pagination to reduce the volume of API messages" do
  query_param :id, "Filter by ID and only return those requests with matching ID"
  query_param :path, "Only include requests made on a given path"
  query_param :page, "Flip to a given page number"
end
get '/callback/?' do
  content_type :json
  size=10
  from = params[:page].nil? ? 1 : params[:page].to_i

  visible_requests = requests

  # Allow users to filter by incoming id value using ?id=1235
  unless params[:id].nil?
    visible_requests = visible_requests.select { |r| r["id"] == params[:id] }
  end

  # Allow users to filter by path using ?path=/callback
  unless params[:path].nil?
    visible_requests = visible_requests.select { |r| r["request"]["path"] == params[:path] }
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

 
documentation "Remove all the stored messages"
get '/callback/clear' do
  requests = []
  content_type :json
  { :request => "cleared" }.to_json()
end



documentation "View a callback in isolation" do
  param :id, "The system GUID of the message you want to look at"
end
get '/callback/:id' do |id|
  content_type :json
  callback_request = requests.select { |r| r["guid"] == id }

  body = callback_request.to_json()
end

documentation "Remove a callback event from the array" do
  param :id, "The system GUID of the message you want to remove"
end
get '/callback/:id/delete' do |id|
  content_type :json
  requests.delete_if{ |request| request["guid"] == id }

  body = "OK".to_json
end



documentation "I'm a Teapot" do
  payload "I'm a tea pot!"
  status 418
end
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


doc_endpoint "/doc"
