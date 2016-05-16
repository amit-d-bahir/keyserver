require 'sinatra'
require_relative 'keyserver'
require 'pry'

keyserver = KeyServer.new
invalid_key = 'Invalid key'

# Refresh the contents of keys every second
Thread.new do
  loop do
    sleep 1
    keyserver.refresh_contents
  end
end

get '/' do
  'Server is working'
end

get '/generate_keys' do
  keys = keyserver.generate_keys
  keys.join('<br />')
end

get '/block/:key' do
  response = keyserver.block_key(params['key'])
  if response.nil?
    status 404
    body invalid_key
  else
    body 'Successfully blocked'
  end
end

get '/unblock/:key' do
  response = keyserver.unblock_key(params['key'])
  if response.nil?
    status 404
    body invalid_key
  else
    body 'Successfully unblocked'
  end
end

get '/delete/:key' do
  response = keyserver.delete_key(params['key'])
  if response.nil?
    status 404
    body invalid_key
  else
    body 'Successfully deleted'
  end
end

get '/showall' do
  hash = { blocked_keys: keyserver.blocked_keys.join('<br />'),
           unblocked_keys: keyserver.unblocked_keys.join('<br />'),
           deleted_keys: keyserver.deleted_keys.join('<br />') }
  erb :showall, locals: hash
end

get '/ping/:key' do
  response = keyserver.ping_key(params['key'])
  if response.nil?
    status 404
    body invalid_key
  else
    body 'Key timestamp refreshed'
  end
end

get '/serve_key' do
  key = keyserver.serve_key
  if key.nil?
    status 404
    body 'No key available! Please generate some keys...'
  else
    body key
  end
end
