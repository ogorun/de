require 'test/unit'
require 'de'

class DeOperatorTest < Test::Unit::TestCase

  class SomeOperator < De::Operator; end
  class SomeValidOperand < De::Operand;
    def valid?
      true
    end
  end
  class SomeInvalidOperand < De::Operand;
    def valid?
      false
    end
  end

  def test_constructor
    assert_raise(De::Error::AbstractClassObjectCreationError, "Cannot create operator object") { De::Operator.new('some name', 'some content') }

    assert_nothing_raised(De::Error::AbstractClassObjectCreationError) {
      operator =  SomeOperator.new('some name',  'some operator')
      assert_equal('some name', operator.name)
      assert_equal(1, operator.size, 'No children noDes should be added')

      operator2 = SomeOperator.new('another name', 'some operator', [operator])
      assert_equal(2, operator2.size, 'First operator should be adDed as child to second one')
      assert_equal(operator, operator2.children[0], 'First operator should be added as child to second one')
    }

    assert_raise(De::Error::TypeError, "Cannot create operator object") { SomeOperator.new('some name', 'some operator', 10) }
  end

  def test_valid?

    operator =  SomeOperator.new('some name', 'some operator')
    assert_equal(false, operator.valid?)

    operand = SomeValidOperand.new('another name', 5)
    operator << operand
    assert_equal(true, operator.valid?)

    operand2 = SomeInvalidOperand.new('third name', 7)
    operator << operand2
    assert_equal(false, operator.valid?)

  end
end
