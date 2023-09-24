# frozen_string_literal: true

require_relative '../ast/statement'

class DoNothing < AST::Statement::DoNothing
  def to_ruby
    '-> e { e }'
  end
end

class Assign < AST::Statement::Assign
  def to_ruby
    "-> e { e.merge(#{name.inspect} => (#{expression.to_ruby}).call(e)) }"
  end
end

class If < AST::Statement::If
  def to_ruby
    "-> e { if (#{condition.to_ruby}).call(e) then (#{consequence.to_ruby}).call(e) else (#{alternative.to_ruby}).call(e) end }"

    # 改行をするほうが見やすいかもしれない
    # "-> e { " +
    #   "if (#{condition.to_ruby}).call(e)"+
    #   " then (#{consequence.to_ruby}).call(e)"+
    #   " else (#{alternative.to_ruby}).call(e)"+
    #   " end }"
  end
end

class Sequence < AST::Statement::Sequence
  def to_ruby
    "-> e { (#{second.to_ruby}).call((#{first.to_ruby}).call(e)) }"
  end
end

class While < AST::Statement::While
  def to_ruby
    # 1行で、RubyのWhileの構文を描いているので、セミコロンが必要
    # 最後の e は 環境を返している(Statementは環境を返すぞ！)
    "-> e { while (#{condition.to_ruby}).call(e); e = (#{body.to_ruby}).call(e);  end; e}"
  end
end
