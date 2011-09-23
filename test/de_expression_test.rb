require 'test/unit'
require File.expand_path('../lib/de.rb', File.dirname(__FILE__))

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
    operator = SomeOperator.new('some operator', 'some operator')
    assert_nothing_raised(De::Error::TypeError) { @expression << operator }
    assert_equal(@expression.children[0], operator)

    operand = SomeOperand.new('some operand', 'operand content')
    assert_nothing_raised(De::Error::TypeError) { @expression << operand }
    assert_equal(@expression.children[1], operand)

    obj = Object.new
    assert_raise(De::Error::TypeError, "Cannot add object to expression") { @expression << obj }
    assert_equal(3, @expression.size)

    old_name = operand.name
    @expression << operand
    assert_equal(4, @expression.size)
    assert_instance_of(SomeOperand, @expression.children[2])
    assert_equal(operand.name, @expression.children[2].name)
    assert(old_name != @expression.children[2].name)
  end

  def test_valid?
    assert_raise(De::Error::MethodShouldBeOverridenByExtendingClassError, "Cannot add object to expression") { @expression.valid? }
  end
  
  def test_to_s
    assert_equal('some content', @expression.to_s)

    operand = SomeOperand.new('some operand', 'operand content')
    @expression << operand

    assert_equal('some content(operand content)', @expression.to_s)

    operand = SomeOperand.new('some operand 2', 'operand content 2')
    @expression << operand
    assert_equal('some content(operand content, operand content 2)', @expression.to_s)
  end
end
