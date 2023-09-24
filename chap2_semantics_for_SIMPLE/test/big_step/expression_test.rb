# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../../lib/big_step/expression'

class ExpressionTest < Minitest::Test
  class ValueTest < Minitest::Test
    class NumberTest < Minitest::Test
      def test_evaluate_number
        env = {}
        expression = Number.new(1)

        assert_equal expression.evaluate(env), Number.new(1)
      end
    end

    class BooleanTest < Minitest::Test
      def test_evaluate_boolean_true
        env = {}
        expression = Boolean.new(true)

        assert_equal expression.evaluate(env), Boolean.new(true)
      end

      def test_evaluate_boolean_false
        env = {}
        expression = Boolean.new(false)

        assert_equal expression.evaluate(env), Boolean.new(false)
      end
    end
  end

  class AddTest < Minitest::Test
    def test_evaluate_add_when_leaves_are_non_reducible
      env = {}
      expression = Add.new(Number.new(1), Number.new(2))

      assert_equal Number.new(3), expression.evaluate(env)
    end

    def test_evaluate_add_when_leaves_are_reducible
      env = {}
      expression = Add.new(
        Add.new(Number.new(1), Number.new(2)),
        Add.new(Number.new(4), Number.new(8))
      )
      assert_equal Number.new(15), expression.evaluate(env)
    end
  end

  class MultiplyTest < Minitest::Test
    def test_evaluate_multiply_when_leaves_are_non_reducible
      env = {}
      expression = Multiply.new(Number.new(1), Number.new(2))

      assert_equal Number.new(2), expression.evaluate(env)
    end

    def test_evaluate_multiply_when_leaves_are_reducible
      env = {}
      expression = Multiply.new(
        Multiply.new(Number.new(1), Number.new(2)),
        Multiply.new(Number.new(4), Number.new(8))
      )

      assert_equal Number.new(64), expression.evaluate(env)
    end
  end

  class LessThanTest < Minitest::Test
    def test_evaluate_true
      env = {}
      expression = LessThan.new(Number.new(1), Number.new(2))

      assert_equal Boolean.new(true), expression.evaluate(env)
    end

    def test_evaluate_false
      env = {}
      expression = LessThan.new(Number.new(2), Number.new(1))
      assert_equal Boolean.new(false), expression.evaluate(env)
    end
  end

  class VariableTest < Minitest::Test
    def test_evaluate_1
      env = { x: Number.new(1) }
      expression = Variable.new(:x)

      assert_equal Number.new(1), expression.evaluate(env)
    end

    def test_evaluate_2
      env = { x: Number.new(1), y: Number.new(2) }
      expression = Add.new(Variable.new(:x), Variable.new(:y))

      assert_equal Number.new(3), expression.evaluate(env)
    end
  end
end
