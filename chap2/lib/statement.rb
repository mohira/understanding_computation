# frozen_string_literal: true

class DoNothing
  def to_s
    'do-nothing'
  end

  def inspect
    "«#{self}»"
  end

  def ==(other)
    other.is_a?(DoNothing)
  end

  def reducible?
    false
  end
end

class Assign < Struct.new(:name, :expression)
  def to_s
    "#{name} = #{expression}"
  end

  def inspect
    "«#{self}»"
  end

  def reducible?
    true
  end

  def reduce(environment)
    if expression.reducible?
      [Assign.new(name, expression.reduce(environment)), environment]
    else
      [DoNothing.new, environment.merge({ name => expression })]
    end
  end
end

class If < Struct.new(:condition, :consequence, :alternative)
  def to_s
    "if (#{condition}) { #{consequence} } else { #{alternative} }"
  end

  def inspect
    "«#{self}»"
  end

  def reducible?
    true
  end

  def reduce(environment)
    # if文の簡約では環境は変化しない
    if condition.reducible?
      [If.new(condition.reduce(environment), consequence, alternative), environment]
    elsif condition == Boolean.new(true)
      [consequence, environment]
    elsif condition == Boolean.new(false)
      [alternative, environment]
    end
  end
end

class Sequence < Struct.new(:first, :second)
  def to_s
    "#{first}; #{second}"
  end

  def inspect
    "«#{self}»"
  end

  def reducible?
    true
  end

  def reduce(environment)
    case first
    when DoNothing.new
      [second, environment]
    else
      reduced_first, new_environment = first.reduce(environment)
      [Sequence.new(reduced_first, second), new_environment]
    end
  end
end

class While < Struct.new(:condition, :body)
  def to_s
    "while(#{condition}) { #{body} }"
  end

  def inspect
    "«#{self}»"
  end

  def reducible?
    true
  end

  def reduce(environment)
    # consequenceが肝なので、変数に抽出しています
    consequence = Sequence.new(
      body,
      While.new(condition, body) # selfでもいいけど、Whileのほうが規則がわかりやすいじゃん？
    )

    [If.new(condition, consequence, DoNothing.new), environment]
  end

end
