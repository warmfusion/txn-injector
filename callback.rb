require 'sinatra'

post '/' do
  puts URI.unescape( params[:data] )
end

get '/' do
  puts "Only POST is supported"
end
