# frozen_string_literal: true

require 'set'

class FARule < Struct.new(:state, :character, :next_state)
  def applies_to?(state, character)
    (self.state == state) && (self.character == character)
  end

  def follow
    # 規則を適用するときに機械をどのように変更するかを返す #follow メソッドを持ちます
    next_state
  end

  def inspect
    "#<FARule  #{state.inspect} --#{character}--> #{next_state.inspect}>"
  end
end

class NFARuleBook < Struct.new(:rules)
  def next_states(states, character)
    states.flat_map { |state| follow_rules_for(state, character) }.to_set
  end

  def follow_rules_for(state, character)
    rules_for(state, character).map(&:follow)
  end

  def rules_for(state, character)
    rules.select { |rule| rule.applies_to?(state, character) }
  end

  def follow_free_moves(states)
    more_states = next_states(states, nil) # nilです！

    # 技術的に言うと、
    # これは「自由移動にしたがって状態を追加する」関数の"不動点"を計算しています。
    if more_states.subset?(states) # 停止の条件
      states
    else
      # 与えられた states の和集合
      # 与えられた状態 と 自由移動先の状態 が含まれる！
      # 「自由移動先の状態の集合」**ではない**よ
      follow_free_moves(states + more_states)
    end
  end

end

class NFA < Struct.new(:current_states, :accept_states, :rulebook)
  def accepting?
    # current_states が Set型なので、 accept_states が Array でも & は 積集合の挙動になる
    (current_states & accept_states).any?
  end

  def read_character(character)
    self.current_states = rulebook.next_states(current_states, character)
  end

  def read_string(string)
    string.chars.each do |character|
      read_character(character)
    end
  end

  # このオーバーライドの違和感！ Rubyっぽいのか？
  def current_states
    rulebook.follow_free_moves(super)
  end
end

class NFADesign < Struct.new(:start_state, :accept_states, :rulebook)
  def accepts?(string)
    to_nfa.tap { |nfa| nfa.read_string(string) }.accepting?
  end

  def to_nfa
    NFA.new(Set[start_state], accept_states, rulebook)
  end
end
