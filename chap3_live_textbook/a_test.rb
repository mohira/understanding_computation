require 'minitest/autorun'
require_relative 'a'

class Chap3Test < Minitest::Test
  def test_p67
    rules = [
      FARule.new(1, 'a', 2), FARule.new(1, 'b', 1),
      FARule.new(2, 'a', 2), FARule.new(2, 'b', 3),
      FARule.new(3, 'a', 3), FARule.new(3, 'b', 3),
    ]
    rulebook = DFARulebook.new(rules)

    # p rulebook
    assert_equal 2, rulebook.next_state(1, 'a')
    assert_equal 1, rulebook.next_state(1, 'b')
    assert_equal 3, rulebook.next_state(2, 'b')
  end
end