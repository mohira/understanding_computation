# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../../lib/denotation/expression'
require_relative '../../lib/denotation/statement'

class StatementTest < Minitest::Test
  class DoNothingTest < Minitest::Test
    def test_to_ruby_do_nothing
      statement = DoNothing.new

      expected = '-> e { e }'
      assert_equal expected, statement.to_ruby
    end

    def test_eval
      statement = DoNothing.new

      env = {}
      expected = {}

      assert_equal expected, eval(statement.to_ruby).call(env)
    end
  end

  class AssignTest < Minitest::Test
    def test_to_ruby_assign_1
      statement = Assign.new(:x, Number.new(1))

      expected = '-> e { e.merge(:x => (-> e { 1 }).call(e)) }'
      assert_equal expected, statement.to_ruby
    end

    def test_to_ruby_assign_2
      statement = Assign.new(:x, Add.new(Number.new(1), Number.new(2)))

      expected = '-> e { e.merge(:x => (-> e { (-> e { 1 }).call(e) + (-> e { 2 }).call(e) }).call(e)) }'
      assert_equal expected, statement.to_ruby
    end

    def test_eval_1
      statement = Assign.new(:x, Number.new(1))

      env = {}
      expected = { x: 1 }

      assert_equal expected, eval(statement.to_ruby).call(env)
    end

    def test_eval_2
      statement = Assign.new(:x, Add.new(Number.new(1), Number.new(2)))

      env = {}
      expected = { x: 3 }

      assert_equal expected, eval(statement.to_ruby).call(env)
    end
  end

  class IfTest < Minitest::Test
    def test_to_ruby_if_1
      # if (true) { y = 1 } else { y = 2 }  | { x -> true }
      statement = If.new(Boolean.new(true), Number.new(1), Number.new(2))

      expected = '-> e { if (-> e { true }).call(e) then (-> e { 1 }).call(e) else (-> e { 2 }).call(e) end }'
      assert_equal expected, statement.to_ruby
    end

    def test_to_ruby_if_no_else_clause
      # if (x) { y = 1 }  | {x -> true}
      statement = If.new(
        Variable.new(:x),
        Assign.new(:y, Number.new(1)),
        DoNothing.new # ← ここがミソ！
      )

      expected = '-> e { if (-> e { e[:x] }).call(e) then (-> e { e.merge(:y => (-> e { 1 }).call(e)) }).call(e) else (-> e { e }).call(e) end }'
      assert_equal expected, statement.to_ruby
    end

    def test_eval_1
      statement = If.new(Boolean.new(true), Number.new(1), Number.new(2))

      env = {}
      expected = 1

      assert_equal expected, eval(statement.to_ruby).call(env)
    end

    def test_eval_2
      statement = If.new(Variable.new(:x), Assign.new(:y, Number.new(1)), DoNothing.new)

      env = { x: true }
      expected = { x: true, y: 1 }

      assert_equal expected, eval(statement.to_ruby).call(env)
    end
  end

  class SequenceTest < Minitest::Test
    def test_to_ruby_sequence_1
      statement = Sequence.new(
        Assign.new(:x, Number.new(1)),
        Assign.new(:y, Number.new(1))
      )

      expected = '-> e { (-> e { e.merge(:y => (-> e { 1 }).call(e)) }).call((-> e { e.merge(:x => (-> e { 1 }).call(e)) }).call(e)) }'
      assert_equal expected, statement.to_ruby
    end

    def test_eval_1
      statement = Sequence.new(
        Assign.new(:x, Number.new(1)),
        Assign.new(:y, Number.new(1))
      )

      env = {}
      expected = { x: 1, y: 1 }

      assert_equal expected, eval(statement.to_ruby).call(env)
    end
  end

  class WhileTest < Minitest::Test
    def test_to_ruby_while_1
      # while (x < 5) { x = x * 3} | { x-> 1}
      statement = While.new(
        LessThan.new(Variable.new(:x), Number.new(5)),
        Assign.new(:x, Multiply.new(Variable.new(:x), Number.new(3)))
      )

      expected = '-> e { while (-> e { (-> e { e[:x] }).call(e) < (-> e { 5 }).call(e) }).call(e); e = (-> e { e.merge(:x => (-> e { (-> e { e[:x] }).call(e) * (-> e { 3 }).call(e) }).call(e)) }).call(e);  end; e}'
      assert_equal expected, statement.to_ruby
    end

    def test_eval_1
      statement = While.new(
        LessThan.new(Variable.new(:x), Number.new(5)),
        Assign.new(:x, Multiply.new(Variable.new(:x), Number.new(3)))
      )

      env = { x: 1 }
      expected = { x: 9 }

      assert_equal expected, eval(statement.to_ruby).call(env)
    end
  end
end
