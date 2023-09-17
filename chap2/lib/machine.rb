# frozen_string_literal: true

class Machine < Struct.new(:statement, :environment)
  def step
    self.statement, self.environment = statement.reduce(environment)
  end

  def run
    puts "👺 #{statement} | #{environment}"

    while statement.reducible?
      step
      puts "#{statement} | #{environment}"
    end

    [statement, environment]
  end
end
