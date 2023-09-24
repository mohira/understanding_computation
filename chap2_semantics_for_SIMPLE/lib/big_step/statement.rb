# frozen_string_literal: true

require_relative '../ast/statement'

class DoNothing < AST::Statement::DoNothing
  def evaluate(_environment)
    self
  end
end

class Assign < AST::Statement::Assign
  def evaluate(environment)
    environment.merge({ name => expression.evaluate(environment) })
  end
end

class If < AST::Statement::If
  def evaluate(environment)
    case condition.evaluate(environment)
    when Boolean.new(true)
      consequence.evaluate(environment)
    when Boolean.new(false)
      alternative.evaluate(environment)
    end
  end
end

class Sequence < AST::Statement::Sequence
  def evaluate(environment)
    new_env = first.evaluate(environment)

    second.evaluate(new_env)
  end
end

class While < AST::Statement::While
  def evaluate(environment)
    case condition.evaluate(environment)
    when Boolean.new(true)
      new_env = body.evaluate(environment)

      # evaluate(new_env) <- こう書く方が短くはなるが理解しづらいのでやめた
      While.new(condition, body).evaluate(new_env)
    when Boolean.new(false)
      environment
    end
  end
end
