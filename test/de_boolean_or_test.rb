require 'test/unit'
require 'de'
require 'de/boolean'

class DeBooleanOrTest < Test::Unit::TestCase

  def test_constructor
    assert_nothing_raised(De::Error::AbstractClassObjectCreationError) { De::Boolean::Or.new }
    assert_nothing_raised(De::Error::AbstractClassObjectCreationError) { De::Boolean::Or.new([De::Boolean::Operand.new('some name', true)]) }
  end

  def test_add
    or1 = De::Boolean::Or.new
    operand1 = De::Boolean::Operand.new('some name', true)

    or1 << operand1
    assert_equal(2, or1.size)

    or2 = De::Boolean::Or.new
    or1 << or2
    assert_equal(3, or1.size)
  end

  def test_evaluate
    or1 = De::Boolean::Or.new
    operand_true1 = De::Boolean::Operand.new('some name', true)
    operand_true2 = De::Boolean::Operand.new('second name', true)
    operand_false1 = De::Boolean::Operand.new('third name', false)
    operand_false2 = De::Boolean::Operand.new('fourth name', false)

    or1 << operand_true1
    or1 << operand_true2
    assert_equal(true, or1.evaluate)

    or2 = De::Boolean::Or.new
    or2 << operand_true1
    or2 << operand_false1
    assert_equal(true, or2.evaluate)

    or3 = De::Boolean::Or.new([operand_false1, operand_false2])
    assert_equal(false, or3.evaluate)

    or1 << or3
    assert_equal(true, or1.evaluate)

    or4 = De::Boolean::Or.new([operand_true1, operand_true2])
    or1 << or4
    assert_equal(true, or1.evaluate)
  end

end
