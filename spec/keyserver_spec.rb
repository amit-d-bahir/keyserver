require_relative '../keyserver.rb'

describe KeyServer do
  describe 'KeyServer#get_random_key' do
    it 'can generate random key of length 30' do
      expect(KeyServer.new.get_random_key.length).to eq(30)
    end
  end

  describe 'KeyServer#generate_keys' do
    before do

    end


  end

end
