require 'minitest/autorun'
require_relative 'a'

class Chap3Test < Minitest::Test
  def test_p67_dfa_rulebook
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

  def test_p68_accept_or_reject?
    rules = [
      FARule.new(1, 'a', 2), FARule.new(1, 'b', 1),
      FARule.new(2, 'a', 2), FARule.new(2, 'b', 3),
      FARule.new(3, 'a', 3), FARule.new(3, 'b', 3),
    ]
    rulebook = DFARulebook.new(rules)

    assert DFA.new(1, [1, 3], rulebook).accepting?

    refute DFA.new(2, [1, 3], rulebook).accepting?
    refute DFA.new(1, [3], rulebook).accepting?
  end

  def test_p68_read_character
    rules = [
      FARule.new(1, 'a', 2), FARule.new(1, 'b', 1),
      FARule.new(2, 'a', 2), FARule.new(2, 'b', 3),
      FARule.new(3, 'a', 3), FARule.new(3, 'b', 3),
    ]
    rulebook = DFARulebook.new(rules)

    dfa = DFA.new(1, [3], rulebook)
    assert_equal 1, dfa.current_state
    refute dfa.accepting?

    dfa.read_character('b')
    assert_equal 1, dfa.current_state
    refute dfa.accepting?

    3.times { dfa.read_character('a') }
    assert_equal 2, dfa.current_state
    refute dfa.accepting?

    dfa.read_character('b')
    assert_equal 3, dfa.current_state
    assert dfa.accepting?
  end
end