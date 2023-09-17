require 'minitest/autorun'
require_relative 'a'

class ATest < Minitest::Test
  def test_sequence
    # x = 1+1   ; y=x+3 | {}
    # x = 2     ; y=x+3 | {}
    # do-nothing; y=x+3 | { x->2}
    # y=x+3 | { x->2 }
    # y=2+3 | { x->2 }
    # y=5   | { x->2 }
    # do-nothing | { x->2, y->5 }
    expression = Sequence.new(
      Assign.new(:x, Add.new(Number.new(1), Number.new(1))), # x=1+1
      Assign.new(:y, Add.new(Variable.new(:x), Number.new(3))) # y=x+3
    )
    env = {}

    m = Machine.new(expression, env)

    assert_equal [DoNothing.new, { x: Number.new(2), y: Number.new(5) }], m.run
  end

  def test_if_statement_not_else
    # if (x) { y = 1 }  | {x -> true}
    # if (true) { y = 1 } | {x -> true}
    # y = 1 | {x -> true}
    # do-nothing | {x -> true, y->1}
    expression = If.new(
      Variable.new(:x),
      Assign.new(:y, Number.new(1)),
      DoNothing.new # ← ここがミソ！
    )
    env = { x: Boolean.new(true) }

    m = Machine.new(expression, env)

    assert_equal [DoNothing.new, { x: Boolean.new(true), y: Number.new(1) }], m.run
  end

  def test_if_statement
    # if (x) { y = 1 } else { y=2 }    | {x -> true}
    # if (true) { y = 1 } else { y=2 } | {x -> true}
    # y = 1 | {x -> true}
    # do-nothing | {x -> true, y->1}
    expression = If.new(
      Variable.new(:x),
      Assign.new(:y, Number.new(1)),
      Assign.new(:y, Number.new(2)),
    )
    env = { x: Boolean.new(true) }

    m = Machine.new(expression, env)

    assert_equal [DoNothing.new, { x: Boolean.new(true), y: Number.new(1) }], m.run
  end

  def test_p34
    # x = x + 1 | { x->2 }
    expression = Assign.new(:x, Add.new(Variable.new(:x), Number.new(1)))
    env = { x: Number.new(2) }

    m = Machine.new(expression, env)

    assert_equal [DoNothing.new, { x: Number.new(3) }], m.run
  end

  class Archived
    def test_aaa
      expression = Add.new(Variable.new(:x), Variable.new(:y))
      env = { x: Number.new(3), y: Number.new(4) }

      m = Machine.new(expression, env)

      assert_equal Number.new(7), m.run
    end

    def test_add_multipy_expression
      # (1x2)+(3x4)
      expression = Add.new(
        Multiply.new(Number.new(1), Number.new(2)),
        Multiply.new(Number.new(3), Number.new(4)),
      )

      assert expression.reducible?
      r1 = Add.new(Number.new(2), Multiply.new(Number.new(3), Number.new(4)))
      assert_equal r1, expression.reduce

      r2 = Add.new(Number.new(2), Number.new(12))
      assert_equal r2, expression.reduce.reduce

      r3 = Number.new(14)
      assert_equal r3, expression.reduce.reduce.reduce

      refute expression.reduce.reduce.reduce.reducible?
    end

    def test_machine
      expression = Add.new(
        Multiply.new(Number.new(1), Number.new(2)),
        Multiply.new(Number.new(3), Number.new(4)),
      )

      machine = Machine.new(expression)

      assert_equal Number.new(14), machine.run
    end

    def test_less_than_to_boolean
      # 1+2 < 3*4 -> true
      expression = LessThan.new(
        Add.new(Number.new(1), Number.new(2)),
        Multiply.new(Number.new(3), Number.new(4)),
      )

      assert_equal Boolean.new(true), Machine.new(expression).run
    end
  end

end