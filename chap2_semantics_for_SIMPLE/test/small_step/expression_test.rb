# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../../lib/small_step/expression'

class ExpressionTest < Minitest::Test
  class ValueTest < Minitest::Test
    class NumberTest < Minitest::Test
      def test_representation
        expression = Number.new(1)
        assert_equal '1', expression.to_s
        assert_equal '«1»', expression.inspect
      end

      def test_number_is_non_reducible
        refute Number.new(1).reducible?
      end
    end

    class BooleanTest < Minitest::Test
      def test_representation
        expression_true = Boolean.new(true)
        assert_equal 'true', expression_true.to_s
        assert_equal '«true»', expression_true.inspect

        expression_false = Boolean.new(false)
        assert_equal 'false', expression_false.to_s
        assert_equal '«false»', expression_false.inspect
      end

      def test_boolean_is_non_reducible
        refute Boolean.new(true).reducible?
        refute Boolean.new(false).reducible?
      end
    end
  end

  class AddTest < Minitest::Test
    def test_representation
      expression1 = Add.new(Number.new(1), Number.new(2))
      assert_equal '1 + 2', expression1.to_s
      assert_equal '«1 + 2»', expression1.inspect

      expression2 = Add.new(
        Add.new(Number.new(1), Number.new(2)),
        Add.new(Number.new(4), Number.new(8))
      )
      assert_equal '1 + 2 + 4 + 8', expression2.to_s
      assert_equal '«1 + 2 + 4 + 8»', expression2.inspect # 優先順位は読み取れない
    end

    def test_reduce_when_leaves_are_non_reducible
      env = {}
      expression = Add.new(Number.new(1), Number.new(2))

      assert_equal Number.new(3), expression.reduce(env)
    end

    def test_reduce_when_leaves_are_reducible
      env = {}
      expression = Add.new(
        Add.new(Number.new(1), Number.new(2)),
        Add.new(Number.new(4), Number.new(8))
      )

      reduced1 = expression.reduce(env)
      reduced2 = reduced1.reduce(env)
      reduced3 = reduced2.reduce(env)

      assert_equal Add.new(Number.new(3), Add.new(Number.new(4), Number.new(8))), reduced1
      assert_equal Add.new(Number.new(3), Number.new(12)), reduced2
      assert_equal Number.new(15), reduced3
    end
  end

  class MultiplyTest < Minitest::Test
    def test_representation
      expression1 = Multiply.new(Number.new(1), Number.new(2))
      assert_equal '1 * 2', expression1.to_s
      assert_equal '«1 * 2»', expression1.inspect

      expression2 = Multiply.new(
        Multiply.new(Number.new(1), Number.new(2)),
        Multiply.new(Number.new(4), Number.new(8))
      )

      assert_equal '1 * 2 * 4 * 8', expression2.to_s
      assert_equal '«1 * 2 * 4 * 8»', expression2.inspect # 優先順位は読み取れない
    end

    def test_reduce_when_leaves_are_non_reducible
      env = {}
      expression = Multiply.new(Number.new(1), Number.new(2))

      assert_equal Number.new(2), expression.reduce(env)
    end

    def test_reduce_when_leaves_are_reducible
      env = {}
      expression = Multiply.new(
        Multiply.new(Number.new(1), Number.new(2)),
        Multiply.new(Number.new(4), Number.new(8))
      )

      r1 = expression.reduce(env)
      reduced2 = r1.reduce(env)
      reduced3 = reduced2.reduce(env)

      assert_equal Multiply.new(Number.new(2), Multiply.new(Number.new(4), Number.new(8))), r1
      assert_equal Multiply.new(Number.new(2), Number.new(32)), reduced2
      assert_equal Number.new(64), reduced3
    end
  end

  class LessThanTest < Minitest::Test
    def test_representation
      expression1 = LessThan.new(Number.new(1), Number.new(2))
      assert_equal '1 < 2', expression1.to_s
      assert_equal '«1 < 2»', expression1.inspect

      expression2 = LessThan.new(Number.new(2), Number.new(1))
      assert_equal '2 < 1', expression2.to_s
      assert_equal '«2 < 1»', expression2.inspect
    end

    def test_reduce_true
      env = {}
      expression = LessThan.new(Number.new(1), Number.new(2))

      assert_equal Boolean.new(true), expression.reduce(env)
    end

    def test_reduce_false
      env = {}
      expression = LessThan.new(Number.new(2), Number.new(1))

      assert_equal Boolean.new(false), expression.reduce(env)
    end
  end

  class VariableTest < Minitest::Test
    def test_representation
      expression = Variable.new(:x)
      assert_equal 'x', expression.to_s
      assert_equal '«x»', expression.inspect
    end

    def test_reduce_expression_is_value
      env = { x: Number.new(1) }
      expression = Variable.new(:x)

      assert_equal Number.new(1), expression.reduce(env)
    end

    def test_reduce_expression_is_reducible_expression
      env = { x: Number.new(1), y: Number.new(2) }
      expression = Add.new(Variable.new(:x), Variable.new(:y))

      reduced1 = expression.reduce(env)
      reduced2 = reduced1.reduce(env)
      reduced3 = reduced2.reduce(env)

      assert_equal Add.new(Number.new(1), Variable.new(:y)), reduced1
      assert_equal Add.new(Number.new(1), Number.new(2)), reduced2
      assert_equal Number.new(3), reduced3
    end
  end
end
