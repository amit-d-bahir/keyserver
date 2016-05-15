require 'securerandom'
require 'Set'

# KeyServer class handle serving of keys to clients
class KeyServer
  attr_reader :keys, :deleted

  def initialize
    @keys = Hash.new({})
    @deleted = Set.new
  end

  def random_key
    SecureRandom.hex(15)
  end

  def refresh_contents
    current_time = Time.new
    @keys.each do |k, v|
      timedelta = current_time - v['time_stamp']
      v['status'] = 'unblocked' if timedelta >= 60
      delete_key(k) if timedelta >= 300
    end
  end

  def blocked_keys
    refresh_contents
    blocked_keys = @keys.select { |_, v| v['status'] == 'blocked' }
    blocked_keys.keys
  end

  def unblocked_keys
    @keys.keys - blocked_keys
  end

  def serve_key
    unblocked_keys.sample
  end

  def deleted_keys
    refresh_contents
    @deleted.to_a
  end

  def generate_keys
    # Generates and adds 5 random keys in @keys
    new_keys = []
    5.times do
      key = random_key
      key = random_key while @deleted.include?(key)
      new_keys.push(key)
      @keys[key] = { 'time_stamp' => Time.new, 'status' => 'unblocked' }
    end
    new_keys
  end

  def invalid_key?(key)
    @keys[key] == {}
  end

  def block_key(key)
    return ['Invalid key', 404] if invalid_key?(key)
    body = 'Successfully blocked'
    body = 'Already blocked' if @keys[key]['status'] == 'blocked'
    @keys[key]['status'] = 'blocked'
    @keys[key]['time_stamp'] = Time.new
    [body, 200]
  end

  def unblock_key(key)
    return ['Invalid key', 404] if invalid_key?(key)
    body = 'Successfully unblocked'
    body = 'Already unblocked' if @keys[key]['status'] == 'unblocked'
    @keys[key]['status'] = 'unblocked'
    [body, 200]
  end

  def delete_key(key)
    return ['Invalid key', 404] if invalid_key?(key)
    @keys.delete(key)
    @deleted.add(key)
    ['Successfully deleted', 200]
  end

  def ping_key(key)
    return ['Invalid key', 404] if invalid_key?(key)
    @keys[key]['time_stamp'] = Time.new
    ['Key time stamp refreshed', 200]
  end
end
