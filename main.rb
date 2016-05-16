require 'sinatra'
require_relative 'keyserver'

keyserver = KeyServer.new

get '/' do
  'Server is working'
end

get '/generate_keys' do
  keys = keyserver.generate_keys
  keys.join('<br />')
end

get '/block/:key' do
  b, s = keyserver.block_key(params['key'])
  status s
  body b
end

get '/unblock/:key' do
  b, s = keyserver.unblock_key(params['key'])
  status s
  body b
end

get '/delete/:key' do
  b, s = keyserver.delete_key(params['key'])
  status s
  body b
end

get '/showall' do
  hash = { blocked_keys: keyserver.blocked_keys.join('<br />'),
           unblocked_keys: keyserver.unblocked_keys.join('<br />'),
           deleted_keys: keyserver.deleted_keys.join('<br />') }
  erb :showall, locals: hash
end

get '/ping/:key' do
  b, s = keyserver.ping_key(params['key'])
  status s
  body b
end

get '/serve_key' do
  b, s = keyserver.serve_key
  status s
  body b
end
