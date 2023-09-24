# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../../lib/denotation/expression'

class ExpressionTest < Minitest::Test
  class ValueTest < Minitest::Test
    class NumberTest < Minitest::Test
      def test_to_ruby
        expression = Number.new(1)

        assert_equal '-> e { 1 }', expression.to_ruby
      end

      def test_eval
        expression = Number.new(1)

        env = {}
        expected = 1

        assert_equal expected, eval(expression.to_ruby).call(env)
      end
    end

    class BooleanTest < Minitest::Test
      def test_to_ruby_boolean_true
        expression = Boolean.new(true)

        expected = '-> e { true }'
        assert_equal expected, expression.to_ruby
      end

      def test_to_ruby_boolean_false
        expression = Boolean.new(false)

        expected = '-> e { false }'
        assert_equal expected, expression.to_ruby
      end

      def test_eval_true
        expression = Boolean.new(true)

        env = {}
        expected = true

        assert_equal expected, eval(expression.to_ruby).call(env)
      end

      def test_eval_false
        expression = Boolean.new(false)

        env = {}
        expected = false

        assert_equal expected, eval(expression.to_ruby).call(env)
      end
    end
  end

  class AddTest < Minitest::Test
    def test_to_ruby_add_when_leaves_are_non_reducible
      expression = Add.new(Number.new(1), Number.new(2))

      expected = '-> e { (-> e { 1 }).call(e) + (-> e { 2 }).call(e) }'
      assert_equal expected, expression.to_ruby
    end

    def test_to_ruby_add_when_leaves_are_reducible
      expression = Add.new(
        Add.new(Number.new(1), Number.new(2)),
        Add.new(Number.new(4), Number.new(8))
      )

      expected = '-> e { (-> e { (-> e { 1 }).call(e) + (-> e { 2 }).call(e) }).call(e) + (-> e { (-> e { 4 }).call(e) + (-> e { 8 }).call(e) }).call(e) }'
      assert_equal expected, expression.to_ruby
    end

    def test_eval_add_1
      expression = Add.new(Number.new(1), Number.new(2))

      env = {}
      expected = 3

      assert_equal expected, eval(expression.to_ruby).call(env)
    end

    def test_eval_add_2
      expression = Add.new(
        Add.new(Number.new(1), Number.new(2)),
        Add.new(Number.new(4), Number.new(8))
      )

      env = {}
      expected = 15

      assert_equal expected, eval(expression.to_ruby).call(env)
    end
  end

  class MultiplyTest < Minitest::Test
    def test_to_ruby_multiply_when_leaves_are_non_reducible
      expression = Multiply.new(Number.new(1), Number.new(2))

      expected = '-> e { (-> e { 1 }).call(e) * (-> e { 2 }).call(e) }'
      assert_equal expected, expression.to_ruby
    end

    def test_to_ruby_multiply_when_leaves_are_reducible
      expression = Multiply.new(
        Multiply.new(Number.new(1), Number.new(2)),
        Multiply.new(Number.new(4), Number.new(8))
      )
      expected = '-> e { (-> e { (-> e { 1 }).call(e) * (-> e { 2 }).call(e) }).call(e) * (-> e { (-> e { 4 }).call(e) * (-> e { 8 }).call(e) }).call(e) }'
      assert_equal expected, expression.to_ruby
    end

    def test_eval_1
      expression = Multiply.new(Number.new(1), Number.new(2))

      env = {}
      expected = 2

      assert_equal expected, eval(expression.to_ruby).call(env)
    end

    def test_eval_2
      expression = Multiply.new(
        Multiply.new(Number.new(1), Number.new(2)),
        Multiply.new(Number.new(4), Number.new(8))
      )

      env = {}
      expected = 64

      assert_equal expected, eval(expression.to_ruby).call(env)
    end
  end

  class LessThanTest < Minitest::Test
    def test_to_ruby_true
      expression = LessThan.new(Number.new(1), Number.new(2))

      expected = '-> e { (-> e { 1 }).call(e) < (-> e { 2 }).call(e) }'
      assert_equal expected, expression.to_ruby
    end

    def test_to_ruby_false
      expression = LessThan.new(Number.new(2), Number.new(1))

      expected = '-> e { (-> e { 2 }).call(e) < (-> e { 1 }).call(e) }'
      assert_equal expected, expression.to_ruby
    end

    def test_eval_true
      expression = LessThan.new(Number.new(1), Number.new(2))

      env = {}
      expected = true

      assert_equal expected, eval(expression.to_ruby).call(env)
    end

    def test_eval_false
      expression = LessThan.new(Number.new(2), Number.new(1))

      env = {}
      expected = false

      assert_equal expected, eval(expression.to_ruby).call(env)
    end
  end

  class VariableTest < Minitest::Test
    def test_to_ruby_1
      expression = Variable.new(:x)

      expected = '-> e { e[:x] }'
      assert_equal expected, expression.to_ruby
    end

    def test_to_ruby_2
      expression = Add.new(Variable.new(:x), Variable.new(:y))

      expected = '-> e { (-> e { e[:x] }).call(e) + (-> e { e[:y] }).call(e) }'
      assert_equal expected, expression.to_ruby
    end

    def test_eval_1
      expression = Variable.new(:x)

      env = { x: 1 }
      expected = 1

      assert_equal expected, eval(expression.to_ruby).call(env)
    end

    def test_eval_2
      expression = Add.new(Variable.new(:x), Variable.new(:y))

      env = { x: 1, y: 2 }
      expected = 3

      assert_equal expected, eval(expression.to_ruby).call(env)
    end
  end
end
