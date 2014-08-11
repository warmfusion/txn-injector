require 'sinatra'

post '/' do
  URI.unescape( params[:data] )
end

get '/' do
  "Only POST is supported"
end
