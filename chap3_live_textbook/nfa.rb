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
end

class NFADesign < Struct.new(:start_state, :accept_states, :rulebook)
  def accepts?(string)
    to_nfa.tap { |nfa| nfa.read_string(string) }.accepting?
  end

  def to_nfa
    NFA.new(Set[start_state], accept_states, rulebook)
  end
end
