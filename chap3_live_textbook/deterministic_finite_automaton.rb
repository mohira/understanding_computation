# frozen_string_literal: true

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

# Deterministic Finite Automaton
class DFARulebook < Struct.new(:rules)
  def next_state(state, character)
    # 与えられた状態と文字に対して適用可能な規則が 必ず 1 つだけ存在すると仮定してる
    rule_for(state, character).follow
  end

  def rule_for(state, character)
    # 要素に対してブロックを評価した値が真になった最初の要素を返します。
    rules.detect { |rule| rule.applies_to?(state, character) }
  end
end

class DFA < Struct.new(:current_state, :accept_states, :rulebook)
  def accepting?
    accept_states.include?(current_state)
  end

  def read_character(character)
    self.current_state = rulebook.next_state(current_state, character)
  end

  def read_string(string)
    string.chars.each do |character|
      read_character(character)
    end
  end
end

class DFADesign < Struct.new(:start_state, :accept_states, :rulebook)
  def to_dfa
    DFA.new(start_state, accept_states, rulebook)
  end

  def accepts?(string)
    # accepting と違って ing系じゃないね！
    to_dfa.tap { |dfa| dfa.read_string(string) }.accepting?
  end
end
