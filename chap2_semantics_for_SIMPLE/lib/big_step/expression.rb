# frozen_string_literal: true

require_relative '../ast/expression'

class Number < AST::Expression::Number
  def evaluate(_environment)
    self
  end
end

class Boolean < AST::Expression::Boolean
  def evaluate(_environment)
    self
  end
end

class Add < AST::Expression::Add
  def evaluate(environment)
    Number.new(left.evaluate(environment).value + right.evaluate(environment).value)
  end
end

class Multiply < AST::Expression::Multiply
  def evaluate(environment)
    Number.new(left.evaluate(environment).value * right.evaluate(environment).value)
  end
end

class LessThan < AST::Expression::LessThan
  def evaluate(environment)
    Boolean.new(left.evaluate(environment).value < right.evaluate(environment).value)
  end
end

class Variable < AST::Expression::Variable
  def evaluate(environment)
    environment[name]
  end
end
