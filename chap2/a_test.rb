require 'minitest/autorun'
require_relative 'a'

class ATest < Minitest::Test
  def test_a
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
end