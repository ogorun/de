require 'test/unit'
require 'de'
require 'de/boolean'

class DeBooleanOperandTest < Test::Unit::TestCase

  def test_constructor
    assert_nothing_raised(De::Error::AbstractClassObjectCreationError) { De::Boolean::Operand.new('first', true) }
  end

  def test_valid?
    operand1 = De::Boolean::Operand.new('first', true)
    operand2 = De::Boolean::Operand.new('second', false)
    operand3 = De::Boolean::Operand.new('third', 'some string')

    assert_equal(true, operand1.valid?)
    assert_equal(true, operand2.valid?)
    assert_equal(false, operand3.valid?)
  end

  def test_evaluate
    operand1 = De::Boolean::Operand.new('first', true)
    operand2 = De::Boolean::Operand.new('second', false)
    operand3 = De::Boolean::Operand.new('third', 'some string')

    assert_equal(true, operand1.evaluate)
    assert_equal(false, operand2.evaluate)
    assert_raise(De::Error::InvalidExpressionError, "Invalid expression") { operand3.evaluate }
  end
end
