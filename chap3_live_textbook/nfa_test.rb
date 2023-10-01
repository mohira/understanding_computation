# frozen_string_literal: true

require 'set'
require 'minitest/autorun'
require_relative 'nfa'

class NFATest < Minitest::Test
  def test_p74_nfa_1
    # 図3-5
    rules = [
      FARule.new(1, 'a', 1), FARule.new(1, 'b', 1), FARule.new(1, 'b', 2),
      FARule.new(2, 'a', 3), FARule.new(2, 'b', 3),
      FARule.new(3, 'a', 4), FARule.new(3, 'b', 4)
    ]

    rulebook = NFARuleBook.new(rules)

    # p rulebook
    assert_equal Set[1, 2], rulebook.next_states(Set[1], 'b')
    assert_equal Set[1, 3], rulebook.next_states(Set[1, 2], 'a')
    assert_equal Set[1, 2, 4], rulebook.next_states(Set[1, 3], 'b')
  end

  def test_p75_nfa_2
    rules = [
      FARule.new(1, 'a', 1), FARule.new(1, 'b', 1), FARule.new(1, 'b', 2),
      FARule.new(2, 'a', 3), FARule.new(2, 'b', 3),
      FARule.new(3, 'a', 4), FARule.new(3, 'b', 4)
    ]

    rulebook = NFARuleBook.new(rules)

    refute NFA.new(Set[1], [4], rulebook).accepting?
    assert NFA.new(Set[1, 2, 4], [4], rulebook).accepting?
  end

  def test_p75_nfa_3_read_character
    rules = [
      FARule.new(1, 'a', 1), FARule.new(1, 'b', 1), FARule.new(1, 'b', 2),
      FARule.new(2, 'a', 3), FARule.new(2, 'b', 3),
      FARule.new(3, 'a', 4), FARule.new(3, 'b', 4)
    ]

    rulebook = NFARuleBook.new(rules)

    nfa = NFA.new(Set[1], [4], rulebook)
    refute nfa.accepting?

    nfa.read_character('b')
    refute nfa.accepting?

    nfa.read_character('a')
    refute nfa.accepting?

    nfa.read_character('b')
    assert nfa.accepting?
  end

  def test_p75_nfa_4_read_string
    rules = [
      FARule.new(1, 'a', 1), FARule.new(1, 'b', 1), FARule.new(1, 'b', 2),
      FARule.new(2, 'a', 3), FARule.new(2, 'b', 3),
      FARule.new(3, 'a', 4), FARule.new(3, 'b', 4)
    ]

    rulebook = NFARuleBook.new(rules)

    nfa = NFA.new(Set[1], [4], rulebook)

    nfa.read_string('bbbbb')
    assert nfa.accepting?
  end

  def test_p76_nfa_5_nfa_design
    rules = [
      FARule.new(1, 'a', 1), FARule.new(1, 'b', 1), FARule.new(1, 'b', 2),
      FARule.new(2, 'a', 3), FARule.new(2, 'b', 3),
      FARule.new(3, 'a', 4), FARule.new(3, 'b', 4)
    ]

    rulebook = NFARuleBook.new(rules)

    nfa_design = NFADesign.new(1, [4], rulebook)
    assert nfa_design.accepts?('bab')
    assert nfa_design.accepts?('bbbbb')
    assert nfa_design.accepts?('bbbbbbbbbbbbbbbbbbbbbbbbbbbbbb')

    refute nfa_design.accepts?('bbabb')
    refute nfa_design.accepts?('aaaaa')
    refute nfa_design.accepts?('abb')
  end

  class FreeMove < Minitest::Test
    def test_p78_nfa_free_move
      rules = [
        # 自由移動は2パターン
        FARule.new(1, nil, 2), FARule.new(1, nil, 4),

        # 2の倍数の世界
        FARule.new(2, 'a', 3),
        FARule.new(3, 'a', 2),

        # 3の倍数の世界
        FARule.new(4, 'a', 5),
        FARule.new(5, 'a', 6),
        FARule.new(6, 'a', 4),
      ]

      rulebook = NFARuleBook.new(rules)

      assert_equal Set[2, 4], rulebook.next_states(Set[1], nil) # 自由移動するのをシミュレーション
    end

    def test_p79_follow_free_moves
      rules = [
        # 自由移動は2パターン
        FARule.new(1, nil, 2), FARule.new(1, nil, 4),

        # 2の倍数の世界
        FARule.new(2, 'a', 3),
        FARule.new(3, 'a', 2),

        # 3の倍数の世界
        FARule.new(4, 'a', 5),
        FARule.new(5, 'a', 6),
        FARule.new(6, 'a', 4),
      ]

      rulebook = NFARuleBook.new(rules)

      assert_equal Set[1, 2, 4], rulebook.follow_free_moves(Set[1])
    end

    def test_p79_support_free_moves
      # 長さが2の倍数 または 3の倍数 の文字列を受理する
      rules = [
        # 自由移動は2パターン
        FARule.new(1, nil, 2), FARule.new(1, nil, 4),

        # 2の倍数の世界
        FARule.new(2, 'a', 3),
        FARule.new(3, 'a', 2),

        # 3の倍数の世界
        FARule.new(4, 'a', 5),
        FARule.new(5, 'a', 6),
        FARule.new(6, 'a', 4),
      ]

      rulebook = NFARuleBook.new(rules)
      nfa_design = NFADesign.new(1, [2, 4], rulebook)


      # 2の倍数は受理
      assert nfa_design.accepts?('aa')
      assert nfa_design.accepts?('aaaa')

      # 3の倍数は受理
      assert nfa_design.accepts?('aaa')
      assert nfa_design.accepts?('aaaaaa')

      # 受理されない
      refute nfa_design.accepts?('a')
      refute nfa_design.accepts?('aaaaa')
    end
  end
end
