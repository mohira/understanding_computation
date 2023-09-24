# frozen_string_literal: true

require_relative '../ast/expression'

class Number < AST::Expression::Number
  def to_ruby
    "-> e { #{value.inspect} }"
  end
end

class Boolean < AST::Expression::Boolean
  def to_ruby
    "-> e { #{value.inspect} }"
  end
end

class Add < AST::Expression::Add
  def to_ruby
    "-> e { (#{left.to_ruby}).call(e) + (#{right.to_ruby}).call(e) }"
  end
end

class Multiply < AST::Expression::Multiply
  def to_ruby
    "-> e { (#{left.to_ruby}).call(e) * (#{right.to_ruby}).call(e) }"
  end
end

class LessThan < AST::Expression::LessThan
  def to_ruby
    "-> e { (#{left.to_ruby}).call(e) < (#{right.to_ruby}).call(e) }"
  end
end

class Variable < AST::Expression::Variable
  def to_ruby
    "-> e { e[#{name.inspect}] }"
  end
end
