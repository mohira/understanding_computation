# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../lib/expression'
require_relative '../lib/statement'
require_relative '../lib/machine'

class SimpleTest < Minitest::Test
  class ExpressionTest < Minitest::Test
    class ValueTest < Minitest::Test
      def test_number
        expression = Number.new(1)

        refute expression.reducible?
      end

      def test_boolean_true
        expression = Boolean.new(true)

        refute expression.reducible?
        assert_equal true, expression.value
      end

      def test_boolean_false
        expression = Boolean.new(false)

        refute expression.reducible?
        assert_equal false, expression.value
      end
    end

    class AddTest < Minitest::Test
      def test_add_1
        env = {}
        expression = Add.new(
          Number.new(1),
          Number.new(2)
        )

        assert_equal Number.new(3), expression.reduce(env)
      end

      def test_add_2
        env = {}
        expression = Add.new(
          Add.new(Number.new(1), Number.new(2)),
          Number.new(4)
        )

        assert_equal Add.new(Number.new(3), Number.new(4)), expression.reduce(env)
        assert_equal Number.new(7), expression.reduce(env).reduce(env)
      end

      def test_add_3
        env = {}
        expression = Add.new(
          Number.new(1),
          Add.new(Number.new(4), Number.new(8))
        )

        assert_equal Add.new(Number.new(1), Number.new(12)), expression.reduce(env)
        assert_equal Number.new(13), expression.reduce(env).reduce(env)
      end

      def test_add_4
        env = {}
        expression = Add.new(
          Add.new(Number.new(1), Number.new(2)),
          Add.new(Number.new(4), Number.new(8))
        )

        assert_equal Add.new(Number.new(3), Add.new(Number.new(4), Number.new(8))), expression.reduce(env)
        assert_equal Add.new(Number.new(3), Number.new(12)), expression.reduce(env).reduce(env)
        assert_equal Number.new(15), expression.reduce(env).reduce(env).reduce(env)
      end
    end

    class MultiplyTest < Minitest::Test
      def test_multiply_1
        env = {}
        expression = Multiply.new(Number.new(1), Number.new(2))

        assert_equal Number.new(2), expression.reduce(env)
      end

      def test_multiply_2
        env = {}

        expression = Multiply.new(
          Multiply.new(Number.new(1), Number.new(2)),
          Number.new(4)
        )

        assert_equal Multiply.new(Number.new(2), Number.new(4)), expression.reduce(env)
        assert_equal Number.new(8), expression.reduce(env).reduce(env)
      end

      def test_multiply_3
        env = {}

        expression = Multiply.new(
          Number.new(1),
          Multiply.new(Number.new(4), Number.new(8))
        )

        assert_equal Multiply.new(Number.new(1), Number.new(32)), expression.reduce(env)
        assert_equal Number.new(32), expression.reduce(env).reduce(env)
      end

      def test_multiply_4
        env = {}

        expression = Multiply.new(
          Multiply.new(Number.new(1), Number.new(2)),
          Multiply.new(Number.new(4), Number.new(8))
        )

        assert_equal Multiply.new(Number.new(2), Multiply.new(Number.new(4), Number.new(8))), expression.reduce(env)
        assert_equal Multiply.new(Number.new(2), Number.new(32)), expression.reduce(env).reduce(env)
        assert_equal Number.new(64), expression.reduce(env).reduce(env).reduce(env)
      end
    end

    class LessThanTest < Minitest::Test
      def test_1
        env = {}
        expression = LessThan.new(Number.new(1), Number.new(2))

        assert_equal Boolean.new(true), expression.reduce(env)
      end

      def test_2
        env = {}
        expression = LessThan.new(Number.new(2), Number.new(1))

        assert_equal Boolean.new(false), expression.reduce(env)
      end
    end

    class VariableTest < Minitest::Test
      def test_1
        env = { x: Number.new(1) }
        expression = Variable.new(:x)

        assert_equal Number.new(1), expression.reduce(env)
      end

      def test_2
        env = { x: Number.new(1), y: Number.new(2) }
        expression = Add.new(Variable.new(:x), Variable.new(:y))

        assert_equal Add.new(Number.new(1), Variable.new(:y)), expression.reduce(env)
        assert_equal Add.new(Number.new(1), Number.new(2)), expression.reduce(env).reduce(env)
        assert_equal Number.new(3), expression.reduce(env).reduce(env).reduce(env)
      end
    end
  end

  class StatementTest < Minitest::Test
    class DoNothingTest < Minitest::Test
      def test_not_reducible
        refute DoNothing.new.reducible?
      end

      def test_equality
        assert_equal DoNothing.new, DoNothing.new
      end
    end

    class AssignTest < Minitest::Test
      def test_1
        env = {}
        statement = Assign.new(:x, Number.new(1))

        assert_equal [DoNothing.new, { x: Number.new(1) }], statement.reduce(env)
      end

      def test_2
        env0 = {}
        statement = Assign.new(:x, Add.new(Number.new(1), Number.new(2)))

        reduced1, env1 = statement.reduce(env0)
        assert_equal [Assign.new(:x, Number.new(3)), {}], [reduced1, env1]

        reduced2, env2 = reduced1.reduce(env1)
        assert_equal [DoNothing.new, { x: Number.new(3) }], [reduced2, env2]
      end

      def test_3
        env = { x: Number.new(1) }
        statement = Assign.new(:x, Number.new(2))

        assert_equal [DoNothing.new, { x: Number.new(2) }], statement.reduce(env)
      end

      def test_4
        # x = x + 1 | { x->2 }
        env0 = { x: Number.new(2) }
        statement = Assign.new(:x, Add.new(Variable.new(:x), Number.new(1)))

        reduced1, env1 = statement.reduce(env0)
        assert_equal [Assign.new(:x, Add.new(Number.new(2), Number.new(1))), env0], [reduced1, env1]

        reduced2, env2 = reduced1.reduce(env1)
        assert_equal [Assign.new(:x, Number.new(3)), env1], [reduced2, env2]

        reduced3, env3 = reduced2.reduce(env2)
        assert_equal [DoNothing.new, { x: Number.new(3) }], [reduced3, env3]
      end
    end

    class IfTest < Minitest::Test
      def test_1
        # if文の簡約では環境は変化しない
        # if (x) { y = 1 } else { y = 2 }  | { x -> true }
        env0 = { x: Boolean.new(true) }
        statement = If.new(
          Variable.new(:x),
          Assign.new(:y, Number.new(1)),
          Assign.new(:y, Number.new(2))
        )

        reduced1, env1 = statement.reduce(env0)
        assert_equal [If.new(Boolean.new(true), Assign.new(:y, Number.new(1)), Assign.new(:y, Number.new(2))), env0], [reduced1, env1]

        reduced2, env2 = reduced1.reduce(env1)
        assert_equal [Assign.new(:y, Number.new(1)), env0], [reduced2, env2]

        reduced3, env3 = reduced2.reduce(env2)
        assert_equal [DoNothing.new, { x: Boolean.new(true), y: Number.new(1) }], [reduced3, env3]
      end

      def test_2
        # if (x) { y = 1 } else { y = 2 }  | { x -> false }
        env0 = { x: Boolean.new(false) }
        statement = If.new(
          Variable.new(:x),
          Assign.new(:y, Number.new(1)),
          Assign.new(:y, Number.new(2))
        )

        reduced1, env1 = statement.reduce(env0)
        assert_equal [If.new(Boolean.new(false), Assign.new(:y, Number.new(1)), Assign.new(:y, Number.new(2))), env0], [reduced1, env1]

        reduced2, env2 = reduced1.reduce(env1)
        assert_equal [Assign.new(:y, Number.new(2)), env0], [reduced2, env2]

        reduced3, env3 = reduced2.reduce(env2)
        assert_equal [DoNothing.new, { x: Boolean.new(false), y: Number.new(2) }], [reduced3, env3]
      end

      def test_3_no_else_clause
        # if (x) { y = 1 }  | {x -> true}
        env0 = { x: Boolean.new(true) }

        statement = If.new(
          Variable.new(:x),
          Assign.new(:y, Number.new(1)),
          DoNothing.new # ← ここがミソ！
        )

        reduced1, env1 = statement.reduce(env0)
        assert_equal [If.new(Boolean.new(true), Assign.new(:y, Number.new(1)), DoNothing.new), env0], [reduced1, env1]

        reduced2, env2 = reduced1.reduce(env1)
        assert_equal [Assign.new(:y, Number.new(1)), env0], [reduced2, env2]

        reduced3, env3 = reduced2.reduce(env2)
        assert_equal [DoNothing.new, { x: Boolean.new(true), y: Number.new(1) }], [reduced3, env3]
      end
    end

    class SequenceTest < Minitest::Test
      def test_1
        # x = 1+1   ; y=x+3 | {}
        # x = 2     ; y=x+3 | {}
        # do-nothing; y=x+3 | { x->2 }
        # y=x+3             | { x->2 }
        # y=2+3             | { x->2 }
        # y=5               | { x->2 }
        # do-nothing        | { x->2, y->5 }
        env = {}
        statement = Sequence.new(
          Assign.new(:x, Add.new(Number.new(1), Number.new(1))), # x=1+1
          Assign.new(:y, Add.new(Variable.new(:x), Number.new(3))) # y=x+3
        )

        assert_equal [DoNothing.new, { x: Number.new(2), y: Number.new(5) }], Machine.new(statement, env).run
      end

      def test_sequence_in_sequence
        # 3つの文を持つやつを試す
        # Seq(x=1+1, Sew(y=x+3, z=y+5))
        # x = 1 + 1 ; y = x + 3; z = y + 5; | {}
        # x =     2 ; y = x + 3; z = y + 5; | {}
        # do-nothing; y = x + 3; z = y + 5; | { x->2 }
        # y = x + 3 ; z = y + 5;            | { x->2 }
        # y = 2 + 3 ; z = y + 5;            | { x->2 }
        # y =     5 ; z = y + 5;            | { x->2 }
        # do-nothing; z = y + 5;            | { x->2, y->5 }
        # z = y + 5 ;                       | { x->2, y->5 }
        # z = 5 + 5 ;                       | { x->2, y->5 }
        # z =    10 ;                       | { x->2, y->5 }
        # do-nothing;                       | { x->2, y->5, z->10 }
        env = {}
        statement1 = Assign.new(:x, Add.new(Number.new(1), Number.new(1))) # x = 1 + 1
        statement2 = Assign.new(:y, Add.new(Variable.new(:x), Number.new(3))) # y = x + 3
        statement3 = Assign.new(:z, Add.new(Variable.new(:y), Number.new(5))) # z = y + 5

        statement = Sequence.new(statement1, Sequence.new(statement2, statement3))

        assert_equal [DoNothing.new, { x: Number.new(2), y: Number.new(5), z: Number.new(10), }], Machine.new(statement, env).run
      end
    end

    class WhileTest <Minitest::Test
      def test_1
        # while (x < 5) { x = x * 3} | { x-> 1}
        # -----------------------------------------
        # if (x<5)  { x=x*3; while(x<5) { x = x * 3 } } else {do-nothing} | { x->1 }
        # if (1<5)  { x=x*3; while(x<5) { x = x * 3 } } else {do-nothing} | { x->1 }
        # if (true) { x=x*3; while(x<5) { x = x * 3 } } else {do-nothing} | { x->1 }
        # x=x*3; while(x<5) { x = x * 3 } | { x->1 }
        # x=1*3; while(x<5) { x = x * 3 } | { x->1 }
        # x=3;   while(x<5) { x = x * 3 } | { x->1 }
        # do-nothing; while(x<5) { x = x * 3 } | { x->3 }
        # while(x<5) { x = x * 3 } | { x->3 }
        # -----------------------------------------
        # if (x<5)  { x=x*3; while(x<5) {x=x*3} } else { do-nothing } | { x->3 }
        # if (3<5)  { x=x*3; while(x<5) {x=x*3} } else { do-nothing } | { x->3 }
        # if (true) { x=x*3; while(x<5) {x=x*3} } else { do-nothing } | { x->3 }
        # x=x*3; while(x<5) {x=x*3} | { x->3 }
        # x=3*3; while(x<5) {x=x*3} | { x->3 }
        # x=9;   while(x<5) {x=x*3} | { x->3 }
        # do-nothing; while(x<5) {x=x*3} | { x->9 }
        # while(x<5) {x=x*3} | { x->9 }
        # -----------------------------------------
        # if (x<5) {x=x*3; while(x<5) {x=x*3} } else { do-nothing } | { x->9 }
        # if (9<5) {x=x*3; while(x<5) {x=x*3} } else { do-nothing } | { x->9 }
        # if (false) {x=x*3; while(x<5) {x=x*3} } else { do-nothing } | { x->9 }
        # do-nothing | { x->9 }
        # -----------------------------------------

        # while (x < 5) { x = x * 3} | { x-> 1}
        statement = While.new(
          LessThan.new(Variable.new(:x), Number.new(5)),
          Assign.new(:x, Multiply.new(Variable.new(:x), Number.new(3)))
        )
        env = { x: Number.new(1) }

        assert_equal [DoNothing.new, { x: Number.new(9) }], Machine.new(statement, env).run
      end
    end
  end

end
