# frozen_string_literal: true

module AST
  module Statement
    class DoNothing
      def to_s
        'do-nothing'
      end

      def inspect
        "«#{self}»"
      end

      def ==(other)
        other.is_a?(self.class)
      end
    end

    class Assign < Struct.new(:name, :expression)
      def to_s
        "#{name} = #{expression}"
      end

      def inspect
        "«#{self}»"
      end
    end

    class If < Struct.new(:condition, :consequence, :alternative)
      def to_s
        "if (#{condition}) {#{consequence}} else {#{alternative}}"
      end

      def inspect
        "«#{self}»"
      end
    end

    class Sequence < Struct.new(:first, :second)
      def to_s
        "#{first}; #{second}"
      end

      def inspect
        "«#{self}»"
      end
    end

    class While < Struct.new(:condition, :body)
      def to_s
        "while (#{condition}) { #{body} }"
      end

      def inspect
        "«#{self}»"
      end
    end
  end
end
