# frozen_string_literal: true

class Number < Struct.new(:value)
  def to_s
    value.to_s
  end

  def inspect
    "«#{self}»"
  end

  def reducible?
    false
  end

  def evaluate(environment)
    self
  end

  def to_ruby
    "-> e { #{value.inspect} }"
  end

end

class Add < Struct.new(:left, :right)
  def to_s
    "#{left} + #{right}"
  end

  def inspect
    "«#{self}»"
  end

  def reducible?
    true
  end

  def reduce(environment)
    if left.reducible?
      Add.new(left.reduce(environment), right)
    elsif right.reducible?
      # ifでやってるので、ここの時点でleftのreduceは完了している
      Add.new(left, right.reduce(environment))
    else
      Number.new(left.value + right.value)
    end
  end

  def evaluate(environment)
    Number.new(left.evaluate(environment).value + right.evaluate(environment).value)
  end
end

class Multiply < Struct.new(:left, :right)
  def to_s
    "#{left} * #{right}"
  end

  def inspect
    "«#{self}»"
  end

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

  def evaluate(environment)
    Number.new(left.evaluate(environment).value * right.evaluate(environment).value)
  end
end

class Boolean < Struct.new(:value)
  def to_s
    value.to_s
  end

  def inspect
    "«#{self}»"
  end

  def reducible?
    false
  end

  def evaluate(environment)
    self
  end

  def to_ruby
    "-> e { #{value.inspect} }"
  end
end

class LessThan < Struct.new(:left, :right)
  def to_s
    "#{left} < #{right}"
  end

  def inspect
    "«#{self}»"
  end

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

  def evaluate(environment)
    Boolean.new(left.evaluate(environment).value < right.evaluate(environment).value)
  end
end

class Variable < Struct.new(:name)
  def to_s
    name.to_s
  end

  def inspect
    "«#{self}»"
  end

  def reducible?
    true
  end

  def reduce(environment)
    environment[name]
  end

  def evaluate(environment)
    environment[name]
  end

end

class DoNothing
  # 何もしない Statement

  def to_s
    'do-nothing'
  end

  def inspect
    "«#{self}»"
  end

  def ==(other)
    # Structを継承してないから必要だね！
    other.is_a?(DoNothing)
  end

  def reducible?
    false
  end

  def evaluate(environment)
    environment
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

  # x = 1 + 2  | {}
  # x = 3      | {}
  # do-nothing | {[x->3]}
  #
  # MEMO: envも含めたArrayを返すのが今までのExpressionと違うところだね
  def reduce(environment)
    if expression.reducible?
      [Assign.new(name, expression.reduce(environment)), environment]
    else
      [DoNothing.new, environment.merge({ name => expression })]
    end
  end

  def evaluate(environment)
    environment.merge({ name => expression.evaluate(environment) })
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
    if condition.reducible?
      [If.new(condition.reduce(environment), consequence, alternative), environment]
    else
      case condition
      when Boolean.new(true)
        [consequence, environment]
      when Boolean.new(false)
        [alternative, environment]
      else
        raise StandardError, '警告消し'
      end
    end
  end

  def evaluate(environment)
    case condition.evaluate(environment)
    when Boolean.new(true)
      consequence.evaluate(environment)
    when Boolean.new(false)
      alternative.evaluate(environment)
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

  def evaluate(environment)
    new_env = first.evaluate(environment)

    second.evaluate(new_env)
  end

end

class While < Struct.new(:condition, :body)
  def to_s
    "while (#{condition}) { #{body} }"
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

  def evaluate(environment)
    case condition.evaluate(environment)
    when Boolean.new(true)
      new_env = body.evaluate(environment)

      # self. になっている方が、しっくりくるのでこうしてます！
      # 別ファイルの関数がcallされている気がしちゃうのよ。evaluateだけだとね！
      self.evaluate(new_env)
    when Boolean.new(false)
      environment
    end
  end

end

class Machine < Struct.new(:statement, :environment)
  def step
    self.statement, self.environment = statement.reduce(environment)
  end

  def run
    while statement.reducible?
      puts "#{statement} | #{environment}"
      step
    end

    puts "#{statement} | #{environment}"

    # テストのために強引に値を返すよ〜〜
    [statement, environment]
  end
end
