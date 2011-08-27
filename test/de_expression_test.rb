require 'test/unit'
require 'de'

class DeExpressionTest < Test::Unit::TestCase
  class SomeOperator < De::Operator; end
  class SomeOperand < De::Operand; end

  def setup
    @expression = De::Expression.new('some name', 'some content')
  end

  def test_expression_create
    assert_equal('some name', @expression.name)
    assert_equal('some content', @expression.content)
  end

  def test_add
    operator = SomeOperator.new('some operator')
    assert_nothing_raised(De::Error::TypeError) { @expression << operator }
    assert_equal(@expression.children[0], operator)

    operand = SomeOperand.new('some operand', 'operand content')
    assert_nothing_raised(De::Error::TypeError) { @expression << operand }
    assert_equal(@expression.children[1], operand)

    obj = Object.new
    assert_raise(De::Error::TypeError, "Cannot add object to expression") { @expression << obj }
    assert_equal(3, @expression.size)
  end

  def test_valid?
    assert_raise(De::Error::MethodShouldBeOverridenByExtendingClassError, "Cannot add object to expression") { @expression.valid? }
  end
  
end
