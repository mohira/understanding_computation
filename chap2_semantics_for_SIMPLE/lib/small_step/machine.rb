# frozen_string_literal: true

class Machine < Struct.new(:statement, :environment)
  def next_step
    self.statement, self.environment = statement.reduce(environment)
  end

  def run(debug: false)
    puts "👺\n#{statement} | #{environment}" if debug

    while statement.reducible?
      next_step

      puts "#{statement} | #{environment}" if debug
    end

    [statement, environment]
  end
end
