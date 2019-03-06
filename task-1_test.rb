require 'minitest/autorun'
require './task-1'

class Task1Test < Minitest::Test
  def setup
    File.write('result.json', '')
    @reference_content = File.read('reference.json')
    @test_file_name = 'data.txt'
  end

  def test_result
    work(@test_file_name)
    assert_equal @reference_content, File.read('result.json')
  end
end
