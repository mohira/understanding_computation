# frozen_string_literal: true

require 'minitest/autorun'
require_relative 'a'

class ATest < Minitest::Test
  def test_while
    # while (x < 5) { x = x * 3} | { x-> 1}
    # -----------------------------------------
    # if (x<5) { x=x*3; while(x<5) { x = x * 3 } } else {do-nothing}  | { x->1 }
    # if (1<5) { x=x*3; while(x<5) { x = x * 3 } } else {do-nothing}  | { x->1 }
    # if (true) { x=x*3; while(x<5) { x = x * 3 } } else {do-nothing} | { x->1 }
    # x=x*3; while(x<5) { x = x * 3 } | { x->1 }
    # x=1*3; while(x<5) { x = x * 3 } | { x->1 }
    # x=3; while(x<5) { x = x * 3 } | { x->1 }
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
    expression = While.new(
      LessThan.new(Variable.new(:x), Number.new(5)),
      Assign.new(:x, Multiply.new(Variable.new(:x), Number.new(3)))
    )
    env = { x: Number.new(1) }

    m = Machine.new(expression, env)

    assert_equal [DoNothing.new, { x: Number.new(9) }], m.run
  end

  def test_sequence_in_seq
    # 3つの文を持つやつを試す
    # Seq(x=1+1, Sew(y=x+3, z=y+5))
    # x = 1+1   ; y=x+3 ; z=y+5| {}
    # ↓
    # do-nothing | { x->2, y->5, z->10}
    statement1 = Assign.new(:x, Add.new(Number.new(1), Number.new(1))) # x=1+1
    statement2 = Assign.new(:y, Add.new(Variable.new(:x), Number.new(3))) # y=x+3
    statement3 = Assign.new(:z, Add.new(Variable.new(:y), Number.new(5))) # z=y+5

    expression = Sequence.new(statement1, Sequence.new(statement2, statement3))
    env = {}

    m = Machine.new(expression, env)

    assert_equal [DoNothing.new, { x: Number.new(2), y: Number.new(5), z: Number.new(10) }], m.run
  end

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
      Assign.new(:y, Number.new(2))
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

  class Archive
    def test_aaa
      expression = Add.new(Variable.new(:x), Variable.new(:y))
      env = { x: Number.new(3), y: Number.new(4) }

      m = Machine.new(expression, env)

      assert_equal Number.new(7), m.run
    end

    def test_add_multiply_expression
      # (1x2)+(3x4)
      expression = Add.new(
        Multiply.new(Number.new(1), Number.new(2)),
        Multiply.new(Number.new(3), Number.new(4))
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
        Multiply.new(Number.new(3), Number.new(4))
      )

      machine = Machine.new(expression)

      assert_equal Number.new(14), machine.run
    end

    def test_less_than_to_boolean
      # 1+2 < 3*4 -> true
      expression = LessThan.new(
        Add.new(Number.new(1), Number.new(2)),
        Multiply.new(Number.new(3), Number.new(4))
      )

      assert_equal Boolean.new(true), Machine.new(expression).run
    end
  end
end
