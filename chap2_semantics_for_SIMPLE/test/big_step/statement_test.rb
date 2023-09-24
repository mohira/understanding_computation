# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../../lib/big_step/statement'

class StatementTest < Minitest::Test
  class DoNothingTest < Minitest::Test
    def test_evaluate_do_nothing
      env = {}
      statement = DoNothing.new

      assert_equal DoNothing.new, statement.evaluate(env)
    end
  end

  class AssignTest < Minitest::Test
    def test_evaluate_assign_1
      env = {}
      statement = Assign.new(:x, Number.new(1))

      expected_env = { x: Number.new(1) }
      assert_equal expected_env, statement.evaluate(env)
    end

    def test_evaluate_assign_2
      env = {}
      statement = Assign.new(:x, Add.new(Number.new(1), Number.new(2)))

      expected_env = { x: Number.new(3) }
      assert_equal expected_env, statement.evaluate(env)
    end

    def test_evaluate_assign_when_has_already_same_variable
      env = { x: Number.new(1) }
      statement = Assign.new(:x, Number.new(2))

      expected_env = { x: Number.new(2) }
      assert_equal expected_env, statement.evaluate(env)
    end

    def test_evaluate_assign_when_use_environment
      env = { x: Number.new(2) }
      statement = Assign.new(:x, Add.new(Variable.new(:x), Number.new(1)))

      expected_env = { x: Number.new(3) }
      assert_equal expected_env, statement.evaluate(env)
    end
  end

  class IfTest < Minitest::Test
    def test_evaluate_if_1
      # if (x) { y = 1 } else { y = 2 }  | { x -> true }
      env = { x: Boolean.new(true) }
      statement = If.new(
        Variable.new(:x),
        Assign.new(:y, Number.new(1)),
        Assign.new(:y, Number.new(2))
      )

      expected_env = { x: Boolean.new(true), y: Number.new(1) }
      assert_equal expected_env, statement.evaluate(env)
    end

    def test_evaluate_if_2
      # if (x) { y = 1 } else { y = 2 }  | { x -> false }
      env = { x: Boolean.new(false) }
      statement = If.new(
        Variable.new(:x),
        Assign.new(:y, Number.new(1)),
        Assign.new(:y, Number.new(2))
      )

      expected_env = { x: Boolean.new(false), y: Number.new(2) }
      assert_equal expected_env, statement.evaluate(env)
    end

    def test_evaluate_if_3_no_else_clause
      # if (x) { y = 1 }  | {x -> true}
      env = { x: Boolean.new(true) }

      statement = If.new(
        Variable.new(:x),
        Assign.new(:y, Number.new(1)),
        DoNothing.new # ← ここがミソ！
      )

      expected_env = { x: Boolean.new(true), y: Number.new(1) }
      assert_equal expected_env, statement.evaluate(env)
    end
  end

  class SequenceTest < Minitest::Test
    def test_evaluate_sequence_1
      env = {}
      statement = Sequence.new(
        Assign.new(:x, Number.new(1)), # x=1
        Assign.new(:y, Add.new(Variable.new(:x), Number.new(3))) # y = x+3
      )

      expected_env = { x: Number.new(1), y: Number.new(4) }
      assert_equal expected_env, statement.evaluate(env)
    end

    def test_evaluate_sequence_2
      # x = 1+1   ; y=x+3 | {}
      env = {}
      statement = Sequence.new(
        Assign.new(:x, Add.new(Number.new(1), Number.new(1))), # x=1+1
        Assign.new(:y, Add.new(Variable.new(:x), Number.new(3))) # y=x+3
      )

      expected_env = { x: Number.new(2), y: Number.new(5) }
      assert_equal expected_env, statement.evaluate(env)
    end

    def test_evaluate_sequence_in_sequence
      # 3つの文を持つやつを試す
      # Seq(x=1+1, Sew(y=x+3, z=y+5))
      statement1 = Assign.new(:x, Add.new(Number.new(1), Number.new(1))) # x = 1 + 1
      statement2 = Assign.new(:y, Add.new(Variable.new(:x), Number.new(3))) # y = x + 3
      statement3 = Assign.new(:z, Add.new(Variable.new(:y), Number.new(5))) # z = y + 5

      env = {}
      statement = Sequence.new(statement1, Sequence.new(statement2, statement3))

      expected_env = { x: Number.new(2), y: Number.new(5), z: Number.new(10) }
      assert_equal expected_env, statement.evaluate(env)
    end
  end

  class WhileTest < Minitest::Test
    def test_evaluate_while_1
      # while (x < 5) { x = x * 3} | { x-> 1}
      statement = While.new(
        LessThan.new(Variable.new(:x), Number.new(5)),
        Assign.new(:x, Multiply.new(Variable.new(:x), Number.new(3)))
      )
      env = { x: Number.new(1) }

      expected_env = { x: Number.new(9) }
      assert_equal expected_env, statement.evaluate(env)
    end
  end
end
