# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../../lib/small_step/expression'
require_relative '../../lib/small_step/statement'
require_relative '../../lib/small_step/machine'

class StatementTest < Minitest::Test
  class DoNothingTest < Minitest::Test
    def test_representation
      statement = DoNothing.new

      assert_equal 'do-nothing', statement.to_s
      assert_equal '«do-nothing»', statement.inspect
    end

    def test_do_nothing_is_non_reducible
      refute DoNothing.new.reducible?
    end

    def test_equality
      assert_equal DoNothing.new, DoNothing.new
    end
  end

  class AssignTest < Minitest::Test
    def test_representation
      statement1 = Assign.new(:x, Number.new(1))
      assert_equal 'x = 1', statement1.to_s
      assert_equal '«x = 1»', statement1.inspect

      statement2 = Assign.new(:x, Add.new(Number.new(1), Number.new(2)))
      assert_equal 'x = 1 + 2', statement2.to_s
      assert_equal '«x = 1 + 2»', statement2.inspect
    end

    def test_reduce_1
      env = {}
      statement = Assign.new(:x, Number.new(1))

      assert_equal [DoNothing.new, { x: Number.new(1) }], statement.reduce(env)
    end

    def test_reduce_2
      env = {}
      statement = Assign.new(:x, Add.new(Number.new(1), Number.new(2)))

      statement1, env1 = statement.reduce(env)
      statement2, env2 = statement1.reduce(env1)

      assert_equal [Assign.new(:x, Number.new(3)), env], [statement1, env1]
      assert_equal [DoNothing.new, { x: Number.new(3) }], [statement2, env2]
    end

    def test_reduce_3_has_already_same_variable
      env = { x: Number.new(1) }
      statement = Assign.new(:x, Number.new(2))

      assert_equal [DoNothing.new, { x: Number.new(2) }], statement.reduce(env)
    end

    def test_reduce_4
      env = { x: Number.new(2) }
      statement = Assign.new(:x, Add.new(Variable.new(:x), Number.new(1)))

      statement1, env1 = statement.reduce(env)
      statement2, env2 = statement1.reduce(env1)
      statement3, env3 = statement2.reduce(env2)

      assert_equal [Assign.new(:x, Add.new(Number.new(2), Number.new(1))), env], [statement1, env1]
      assert_equal [Assign.new(:x, Number.new(3)), env1], [statement2, env2]
      assert_equal [DoNothing.new, { x: Number.new(3) }], [statement3, env3]
    end
  end

  class IfTest < Minitest::Test
    def test_representation
      statement = If.new(
        Variable.new(:x),
        Assign.new(:y, Number.new(1)),
        Assign.new(:y, Number.new(2))
      )

      assert_equal 'if (x) {y = 1} else {y = 2}', statement.to_s
      assert_equal '«if (x) {y = 1} else {y = 2}»', statement.inspect
    end

    def test_reduce_1
      # if (x) { y = 1 } else { y = 2 }  | { x -> true }
      env = { x: Boolean.new(true) }
      statement = If.new(
        Variable.new(:x),
        Assign.new(:y, Number.new(1)),
        Assign.new(:y, Number.new(2))
      )

      reduced1, env1 = statement.reduce(env)
      reduced2, env2 = reduced1.reduce(env1)
      assert_equal [If.new(Boolean.new(true), Assign.new(:y, Number.new(1)), Assign.new(:y, Number.new(2))), env], [reduced1, env1]
      assert_equal [Assign.new(:y, Number.new(1)), env], [reduced2, env2]

      # この簡約はAssignの簡約なので環境が変化している(if文の簡約では環境は変化しない)
      reduced3, env3 = reduced2.reduce(env2)
      assert_equal [DoNothing.new, { x: Boolean.new(true), y: Number.new(1) }], [reduced3, env3]
    end

    def test_reduce_2
      # if (x) { y = 1 } else { y = 2 }  | { x -> false }
      env = { x: Boolean.new(false) }
      statement = If.new(
        Variable.new(:x),
        Assign.new(:y, Number.new(1)),
        Assign.new(:y, Number.new(2))
      )

      reduced1, env1 = statement.reduce(env)
      reduced2, env2 = reduced1.reduce(env1)
      assert_equal [If.new(Boolean.new(false), Assign.new(:y, Number.new(1)), Assign.new(:y, Number.new(2))), env], [reduced1, env1]
      assert_equal [Assign.new(:y, Number.new(2)), env], [reduced2, env2]

      reduced3, env3 = reduced2.reduce(env2)
      assert_equal [DoNothing.new, { x: Boolean.new(false), y: Number.new(2) }], [reduced3, env3]
    end

    def test_3_no_else_clause
      # if (x) { y = 1 }  | {x -> true}
      env = { x: Boolean.new(true) }

      statement = If.new(
        Variable.new(:x),
        Assign.new(:y, Number.new(1)),
        DoNothing.new # ← ここがミソ！
      )

      reduced1, env1 = statement.reduce(env)
      reduced2, env2 = reduced1.reduce(env1)
      assert_equal [If.new(Boolean.new(true), Assign.new(:y, Number.new(1)), DoNothing.new), env], [reduced1, env1]
      assert_equal [Assign.new(:y, Number.new(1)), env], [reduced2, env2]

      reduced3, env3 = reduced2.reduce(env2)
      assert_equal [DoNothing.new, { x: Boolean.new(true), y: Number.new(1) }], [reduced3, env3]
    end
  end

  class SequenceTest < Minitest::Test
    def test_representation
      statement = Sequence.new(
        Assign.new(:x, Number.new(1)),
        Assign.new(:y, Add.new(Variable.new(:x), Number.new(3)))
      )

      assert_equal 'x = 1; y = x + 3', statement.to_s
      assert_equal '«x = 1; y = x + 3»', statement.inspect
    end

    def test_reduce_1
      env = {}
      statement = Sequence.new(
        Assign.new(:x, Number.new(1)),
        Assign.new(:y, Add.new(Variable.new(:x), Number.new(3)))
      )

      reduced1, env1 = statement.reduce(env)
      reduced2, env2 = reduced1.reduce(env1)
      assert_equal [Sequence.new(DoNothing.new, Assign.new(:y, Add.new(Variable.new(:x), Number.new(3)))), { x: Number.new(1) }], [reduced1, env1]
      assert_equal [Assign.new(:y, Add.new(Variable.new(:x), Number.new(3))), { x: Number.new(1) }], [reduced2, env2]

      # 以降の簡約はSequenceではなくAssignの簡約なので省略
    end

    def test_reduce_with_virtual_machine
      # x = 1+1   ; y=x+3 | {}
      # x = 2     ; y=x+3 | {}
      # do-nothing; y=x+3 | { x->2 }
      # y=x+3             | { x->2 }
      # y=2+3             | { x->2 }
      # y=5               | { x->2 }
      # do-nothing        | { x->2, y->5 }
      env = {}
      statement = Sequence.new(
        Assign.new(:x, Add.new(Number.new(1), Number.new(1))),
        Assign.new(:y, Add.new(Variable.new(:x), Number.new(3)))
      )

      assert_equal [DoNothing.new, { x: Number.new(2), y: Number.new(5) }], Machine.new(statement, env).run
    end

    def test_reduce_sequence_in_sequence_with_virtual_machine
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
      statement1 = Assign.new(:x, Add.new(Number.new(1), Number.new(1)))
      statement2 = Assign.new(:y, Add.new(Variable.new(:x), Number.new(3)))
      statement3 = Assign.new(:z, Add.new(Variable.new(:y), Number.new(5)))

      env = {}
      statement = Sequence.new(statement1, Sequence.new(statement2, statement3))

      assert_equal [DoNothing.new, { x: Number.new(2), y: Number.new(5), z: Number.new(10), }], Machine.new(statement, env).run
    end
  end

  class WhileTest < Minitest::Test
    def test_representation
      statement = While.new(
        LessThan.new(Variable.new(:x), Number.new(5)),
        Assign.new(:x, Multiply.new(Variable.new(:x), Number.new(3)))
      )

      assert_equal 'while (x < 5) { x = x * 3 }', statement.to_s
      assert_equal '«while (x < 5) { x = x * 3 }»', statement.inspect
    end

    def test_reduce_with_virtual_machine
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

      env = { x: Number.new(1) }
      statement = While.new(
        LessThan.new(Variable.new(:x), Number.new(5)),
        Assign.new(:x, Multiply.new(Variable.new(:x), Number.new(3)))
      )

      assert_equal [DoNothing.new, { x: Number.new(9) }], Machine.new(statement, env).run
    end
  end
end
