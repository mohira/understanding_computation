# frozen_string_literal: true

require_relative '../ast/statement'

class DoNothing < AST::Statement::DoNothing
  def reducible?
    false
  end
end

class Assign < AST::Statement::Assign
  def reducible?
    true
  end

  def reduce(environment)
    if expression.reducible?
      [Assign.new(name, expression.reduce(environment)), environment]
    else
      [DoNothing.new, environment.merge(name => expression)]
    end
  end
end

class If < AST::Statement::If
  def reducible?
    true
  end

  def reduce(environment)
    if condition.reducible?
      [If.new(condition.reduce(environment), consequence, alternative), environment]
    else
      case condition
      when Boolean.new(true)
        [consequence, environment]
      when Boolean.new(false)
        [alternative, environment]
      end
    end
  end
end

class Sequence < AST::Statement::Sequence
  def reducible?
    true
  end

  def reduce(environment)
    case first
    when DoNothing.new
      [second, environment]
    else
      reduced_first_statement, new_environment = first.reduce(environment)

      [Sequence.new(reduced_first_statement, second), new_environment]
    end
  end
end

class While < AST::Statement::While
  def reducible?
    true
  end

  def reduce(environment)
    # consequenceが肝なので、変数に抽出しています
    consequence = Sequence.new(body, self)

    # whileはifに簡約されるだけ
    [If.new(condition, consequence, DoNothing.new), environment]
  end
end
