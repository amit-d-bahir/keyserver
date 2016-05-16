require 'securerandom'
require 'Set'

# KeyServer class handle serving of keys to clients
class KeyServer
  attr_reader :keys, :deleted

  # Constructor
  def initialize
    @keys = Hash.new({})
    @deleted = Set.new
  end

  # Generates a random key of length 30
  def random_key
    SecureRandom.hex(15)
  end

  # Updates key status according to the rules
  def refresh_contents
    current_time = Time.new
    @keys.each do |k, v|
      timedelta = current_time - v['time_stamp']
      v['status'] = 'unblocked' if timedelta >= 60
      delete_key(k) if timedelta >= 300
    end
  end

  # Returns all the blocked keys
  def blocked_keys
    refresh_contents
    blocked_keys = @keys.select { |_, v| v['status'] == 'blocked' }
    blocked_keys.keys
  end

  # Returns all the unblocked keys
  def unblocked_keys
    @keys.keys - blocked_keys
  end

  # Returns all the deleted keys
  def deleted_keys
    refresh_contents
    @deleted.to_a
  end

  # Returns a random key from set of all unblocked keys
  def serve_key
    key = unblocked_keys.sample
    if key.nil?
      status = 404
      body = 'No key available! Please generate some keys...'
    else
      status = 200
      body = key
    end
    [body, status]
  end

  # Generates and adds 5 random keys in @keys
  def generate_keys
    new_keys = []
    5.times do
      key = random_key
      key = random_key while @deleted.include?(key)
      new_keys.push(key)
      @keys[key] = { 'time_stamp' => Time.new, 'status' => 'unblocked' }
    end
    new_keys
  end

  # Checks if a key is generated and not deleted
  def invalid_key?(key)
    @keys[key] == {}
  end

  # Blocks a key for 60 secs
  def block_key(key)
    return ['Invalid key', 404] if invalid_key?(key)
    body = 'Successfully blocked'
    body = 'Already blocked' if @keys[key]['status'] == 'blocked'
    @keys[key]['status'] = 'blocked'
    @keys[key]['time_stamp'] = Time.new
    [body, 200]
  end

  # Unblocks a key
  def unblock_key(key)
    return ['Invalid key', 404] if invalid_key?(key)
    body = 'Successfully unblocked'
    body = 'Already unblocked' if @keys[key]['status'] == 'unblocked'
    @keys[key]['status'] = 'unblocked'
    [body, 200]
  end

  # Deletes a generated key
  def delete_key(key)
    return ['Invalid key', 404] if invalid_key?(key)
    @keys.delete(key)
    @deleted.add(key)
    ['Successfully deleted', 200]
  end

  # Refreshes the timestamp of the given key
  def ping_key(key)
    return ['Invalid key', 404] if invalid_key?(key)
    @keys[key]['time_stamp'] = Time.new
    ['Key time stamp refreshed', 200]
  end
end
