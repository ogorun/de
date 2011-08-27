require 'test/unit'
require 'de'
require 'de/boolean'

class DeBooleanNotTest < Test::Unit::TestCase

  def test_constructor
    assert_nothing_raised(De::Error::AbstractClassObjectCreationError) { De::Boolean::Not.new }
    assert_nothing_raised(De::Error::AbstractClassObjectCreationError) { De::Boolean::Not.new(De::Boolean::Operand.new('some name', true)) }
  end

  def test_add
    not1 = De::Boolean::Not.new
    operand1 = De::Boolean::Operand.new('some name', true)

    not1 << operand1
    assert_equal(2, not1.size)

    not2 = De::Boolean::Not.new
    or1 = De::Boolean::Or.new
    not2 << or1
    assert_equal(1, or1.size)

    assert_raise(De::Error::ArgumentNumerError) { not2 << operand1 }
  end

  def test_evaluate
    not1 = De::Boolean::Not.new
    operand_true1 = De::Boolean::Operand.new('some name', true)
    operand_false1 = De::Boolean::Operand.new('third name', false)

    not1 << operand_true1
    assert_equal(false, not1.evaluate)

    not2 = De::Boolean::Not.new(operand_false1)
    assert_equal(true, not2.evaluate)
  end

end
