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
