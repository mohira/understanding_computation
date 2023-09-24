# frozen_string_literal: true

module AST
  module Expression
    class Number < Struct.new(:value)
      def to_s
        value.to_s
      end

      def inspect
        "«#{self}»"
      end

      def ==(other)
        return false unless other.is_a?(self.class)

        value == other.value
      end
    end

    class Boolean < Struct.new(:value)
      def to_s
        value.to_s
      end

      def inspect
        "«#{self}»"
      end

      def ==(other)
        return false unless other.is_a?(self.class)

        value == other.value
      end
    end

    class Add < Struct.new(:left, :right)
      def to_s
        "#{left} + #{right}"
      end

      def inspect
        "«#{self}»"
      end
    end

    class Multiply < Struct.new(:left, :right)
      def to_s
        "#{left} * #{right}"
      end

      def inspect
        "«#{self}»"
      end
    end

    class LessThan < Struct.new(:left, :right)
      def to_s
        "#{left} < #{right}"
      end

      def inspect
        "«#{self}»"
      end
    end

    class Variable < Struct.new(:name, :value)
      def to_s
        name.to_s
      end

      def inspect
        "«#{self}»"
      end
    end
  end
end
