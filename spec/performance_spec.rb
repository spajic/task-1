require_relative '../task-1.rb'

RSpec.describe "Performance" do
  describe '#parse_user' do
    xit 'works' do
      user1 = "user,0,Hazel,Margarete,19"
      user2 = "user,0,Hazel,Margarete,19"

      expect {
        parse_user(user1)
        parse_user(user2)
      }.to perform_allocation(12)
    end

    it 'works' do
      user1 = "user,0,Hazel,Margarete,19"
      user2 = "user,0,Hazel,Margarete,19"
      DEL = "user,".freeze

      expect {
        user1.delete!(DEL)
        user2.delete!(DEL)
      }.to perform_allocation(3)
    end

    it 'curs' do
      PAT = 'string,'.freeze
      expect {
        'string,two'.delete_prefix!(PAT)
        'string,two'.delete_prefix!(PAT)
        'string,two'.delete_prefix!(PAT)
        'string,two'.delete_prefix!(PAT)
        'string,two'.delete_prefix!(PAT)
      }.to perform_allocation(5)
    end
  end
end
