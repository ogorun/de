require 'test/unit'
require 'de'
require 'de/boolean'

class DeBooleanOperatorTest < Test::Unit::TestCase

  class SomeOperator < De::Boolean::BooleanOperator; end
  class SomeOperator < De::Boolean::BooleanOperator; end
  class NotSuitableOperand < De::Operand; end

  def test_constructor
    assert_raise(De::Error::AbstractClassObjectCreationError) { De::Boolean::BooleanOperator.new('first') }
    assert_nothing_raised(De::Error::AbstractClassObjectCreationError) { SomeOperator.new('some name') }
  end

  def test_add
    operator = SomeOperator.new('first')
    operator2 = SomeOperator.new('second')
    operand = De::Boolean::Operand.new('third', true)
    not_suitable_operand = NotSuitableOperand.new('four', true)

    assert_nothing_raised(De::Error::TypeError) {
      operator << operator2
      assert_equal(2, operator.size)

      operator << operand
      assert_equal(3, operator.size)
    }

    assert_raise(De::Error::TypeError) { operator << not_suitable_operand }

  end

end
