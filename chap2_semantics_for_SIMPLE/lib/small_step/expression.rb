# frozen_string_literal: true

require_relative '../ast/expression'

class Number < AST::Expression::Number
  def reducible?
    false
  end
end

class Boolean < AST::Expression::Boolean
  def reducible?
    false
  end
end

class Add < AST::Expression::Add
  def reducible?
    true
  end

  def reduce(environment)
    if left.reducible?
      Add.new(left.reduce(environment), right)
    elsif right.reducible?
      Add.new(left, right.reduce(environment))
    else
      Number.new(left.value + right.value)
    end
  end
end

class Multiply < AST::Expression::Multiply
  def reducible?
    true
  end

  def reduce(environment)
    if left.reducible?
      Multiply.new(left.reduce(environment), right)
    elsif right.reducible?
      Multiply.new(left, right.reduce(environment))
    else
      Number.new(left.value * right.value)
    end
  end
end

class LessThan < AST::Expression::LessThan
  def reducible?
    true
  end

  def reduce(environment)
    if left.reducible?
      LessThan.new(left.reduce(environment), right)
    elsif right.reducible?
      LessThan.new(left, right.reduce(environment))
    else
      Boolean.new(left.value < right.value)
    end
  end
end

class Variable < AST::Expression::Variable
  def reducible?
    true
  end

  def reduce(environment)
    environment[name]
  end
end
