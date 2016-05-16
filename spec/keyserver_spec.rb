require_relative '../keyserver.rb'

describe KeyServer do
  before do
      @invalid_key = ['Invalid key', 404]
      # A samlple invalid key of length 31
      # We can only get a key of length 30
      @sample_key = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'
  end

  describe 'KeyServer#random_key' do
    it 'can generate random key of length 30' do
      expect(KeyServer.new.random_key.length).to eq(30)
    end
  end

  describe 'KeyServer#generate_keys' do
    it 'can generate 5 random keys' do
      keyserver = KeyServer.new
      keys = keyserver.generate_keys
      expect(keys.length).to eq(5)
      5.times do |i|
        expect(keys[i].length).to eq(30)
      end
    end
  end

  describe 'KeyServer#serve_key' do
    before do
      @keyserver = KeyServer.new
      @no_key = ['No key available! Please generate some keys...', 404]
    end

    it 'can serve a key from the unblocked keys' do
      generated_keys = @keyserver.generate_keys
      @keyserver.block_key(generated_keys[0])
      10.times do
        expect(@keyserver.serve_key).not_to include(generated_keys[0])
      end
    end

    it 'can raise a 404 for no available unblocked keys' do
      expect(@keyserver.serve_key).to eq(@no_key)
    end
  end

  describe 'KeyServer#invalid_key?' do
    before do
      @keyserver = KeyServer.new
      @generated_keys = @keyserver.generate_keys
    end

    it 'can identify a valid key' do
      @generated_keys.each do |key|
        expect(@keyserver.invalid_key?(key)).to eq(false)
      end
    end

    it 'can identify an invalid key' do
        expect(@keyserver.invalid_key?(@sample_key)).to eq(true)
    end

    it 'can return true for deleted keys' do
        @keyserver.delete_key(@generated_keys[0])
        expect(@keyserver.invalid_key?(@generated_keys[0])).to eq(true)
    end
  end

  describe 'KeyServer#block_key' do
    before do
      @keyserver = KeyServer.new
      @generated_keys = @keyserver.generate_keys
      @successful = ['Successfully blocked', 200]
      @already_blocked = ['Already blocked', 200]
    end

    it 'can block a valid unblocked key' do
      expect(@keyserver.block_key(@generated_keys[0])).to eq(@successful)
      expect(@keyserver.keys[@generated_keys[0]]['status']).to eq('blocked')
    end

    it 'can block an already blocked key' do
      @keyserver.block_key(@generated_keys[0])
      expect(@keyserver.block_key(@generated_keys[0])).to eq(@already_blocked)
      expect(@keyserver.keys[@generated_keys[0]]['status']).to eq('blocked')
    end

    it 'can raise a 404 for an invalid key' do
      expect(@keyserver.block_key(@sample_key)).to eq(@invalid_key)
    end
  end

  describe 'KeyServer#unblock_key' do
    before do
      @keyserver = KeyServer.new
      @generated_keys = @keyserver.generate_keys
      @successful = ['Successfully unblocked', 200]
      @already_unblocked = ['Already unblocked', 200]
    end

    it 'can unblock a blocked key' do
      @keyserver.block_key(@generated_keys[0])
      expect(@keyserver.unblock_key(@generated_keys[0])).to eq(@successful)
    end

    it 'can unblock an unblocked key' do
      expect(@keyserver.unblock_key(@generated_keys[0])).to eq(@already_unblocked)
    end

    it 'can raise a 404 for an invalid key' do
      expect(@keyserver.unblock_key(@sample_key)).to eq(@invalid_key)
    end
  end

  describe 'KeyServer#delete_key' do
    before do
      @keyserver = KeyServer.new
      @generated_keys = @keyserver.generate_keys
      @successful = ['Successfully deleted', 200]
    end

    it 'can delete a blocked key' do
      @keyserver.block_key(@generated_keys[0])
      expect(@keyserver.delete_key(@generated_keys[0])).to eq(@successful)
    end

    it 'can delete an unblocked key' do
      expect(@keyserver.delete_key(@generated_keys[0])).to eq(@successful)
    end

    it 'can raise a 404 for an invalid key' do
      expect(@keyserver.delete_key(@sample_key)).to eq(@invalid_key)
    end
  end

  describe 'KeyServer#ping_key' do
    before do
      @keyserver = KeyServer.new
      @generated_keys = @keyserver.generate_keys
    end

    it 'can refresh timestamp of a blocked key' do
      @keyserver.block_key(@generated_keys[0])
      @keyserver.ping_key(@generated_keys[0])
      updated_timestamp = @keyserver.keys[@generated_keys[0]]['time_stamp'].to_i
      expect(updated_timestamp).to eq(Time.new.to_i)
    end

    it 'can refresh timestamp of an unblocked key' do
      @keyserver.ping_key(@generated_keys[0])
      updated_timestamp = @keyserver.keys[@generated_keys[0]]['time_stamp'].to_i
      expect(updated_timestamp).to eq(Time.new.to_i)
    end

    it 'can raise a 404 for invalid key' do
      expect(@keyserver.ping_key(@sample_key)).to eq(@invalid_key)
    end
  end

  describe 'KeyServer#refresh_contents' do
    before do
      @keyserver = KeyServer.new
      @generated_keys = @keyserver.generate_keys
    end

    it 'can change a key status from blocked to unblocked after 60 secs' do
      @keyserver.block_key(@generated_keys[0])
      expect(@keyserver.keys[@generated_keys[0]]['status']).to eq('blocked')
      @keyserver.keys[@generated_keys[0]]['time_stamp'] = Time.new - 61
      @keyserver.refresh_contents
      expect(@keyserver.keys[@generated_keys[0]]['status']).to eq('unblocked')
    end

    it 'can delete a key if it is older than 300 secs' do
      @keyserver.block_key(@generated_keys[0])
      expect(@keyserver.keys[@generated_keys[0]]['status']).to eq('blocked')
      @keyserver.keys[@generated_keys[0]]['time_stamp'] = Time.new - 301
      @keyserver.keys[@generated_keys[1]]['time_stamp'] = Time.new - 301
      @keyserver.refresh_contents
      expect(@keyserver.deleted).to include(@generated_keys[0])
      expect(@keyserver.deleted).to include(@generated_keys[1])
    end
  end

  describe 'KeyServer#blocked_keys' do
    before do
      @keyserver = KeyServer.new
      @generated_keys = @keyserver.generate_keys
    end

    it 'can return empty list if there are no blocked keys' do
      expect(@keyserver.blocked_keys).to eq([])
    end

    it 'can return list of blocked keys' do
      @keyserver.block_key(@generated_keys[0])
      expect(@keyserver.blocked_keys).to eq([@generated_keys[0]])
    end

    it 'can return a list of blocked keys that are not deleted' do
      @keyserver.block_key(@generated_keys[0])
      @keyserver.block_key(@generated_keys[1])
      @keyserver.block_key(@generated_keys[2])
      @keyserver.delete_key(@generated_keys[1])
      expected = [@generated_keys[0], @generated_keys[2]]
      expect(@keyserver.blocked_keys).to eq(expected)
    end
  end

  describe 'KeyServer#unblocked_keys' do
    before do
      @keyserver = KeyServer.new
      @generated_keys = @keyserver.generate_keys
    end

    it 'can return empty list if there are no unblocked keys' do
      keyserver = KeyServer.new
      expect(keyserver.unblocked_keys).to eq([])
      generated_keys = keyserver.generate_keys
      generated_keys.each do |key|
        keyserver.block_key(key)
      end
      expect(keyserver.unblocked_keys).to eq([])
    end

    it 'can return list of unblocked keys' do
      @keyserver.block_key(@generated_keys[0])
      @keyserver.block_key(@generated_keys[1])
      @keyserver.block_key(@generated_keys[2])
      expected = [@generated_keys[3], @generated_keys[4]]
      expect(@keyserver.unblocked_keys).to eq(expected)
    end
  end

  describe 'KeyServer#deleted_keys' do
    before do
      @keyserver = KeyServer.new
      @generated_keys = @keyserver.generate_keys
    end

    it 'can return empty set if there are no deleted keys' do
      expect(@keyserver.deleted_keys.to_a).to eq([])
    end

    it 'can return list of deleted keys' do
      @keyserver.block_key(@generated_keys[0])
      @keyserver.delete_key(@generated_keys[0])
      @keyserver.block_key(@generated_keys[1])
      @keyserver.delete_key(@generated_keys[1])
      expected = [@generated_keys[0], @generated_keys[1]]
      expect(@keyserver.deleted_keys).to eq(expected)
    end
  end
end
