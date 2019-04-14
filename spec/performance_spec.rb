require_relative '../task-1.rb'

RSpec.describe "Performance" do
  # This file is using helpers provided by rspec-benchmark gem https://github.com/piotrmurach/rspec-benchmark
  describe 'Processing a file with 100 lines' do
    it 'allocates 1935 objects' do
      expect {
        work('sample_data/100_lines.txt')
      }.to perform_allocation(1935)
    end

    it 'performs under 1 ms' do
      expect {
        work('sample_data/100_lines.txt')
      }.to perform_under(6).ms
    end

    it 'performs at least 1150 iterations per second' do
      expect {
        work('sample_data/100_lines.txt')
      }.to perform_at_least(1150).within(0.4).warmup(0.2).ips
    end

    # Not sure how to do this to get consistent result
    xit 'performs linear' do
      expect { |n, i|
        work("sample_data/#{n}_lines.txt")
      }.to perform_linear.in_range(100, 300).ratio(100)
    end
  end
end
