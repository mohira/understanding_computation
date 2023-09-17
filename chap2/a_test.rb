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
    assert_equal Add.new(Number.new(2), Multiply.new(Number.new(3), Number.new(4))), expression.reduce
    assert_equal Add.new(Number.new(2), Number.new(12)), expression.reduce.reduce
    assert_equal Number.new(14), expression.reduce.reduce.reduce
    refute expression.reduce.reduce.reduce.reducible?
  end
end