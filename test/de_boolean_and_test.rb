require 'test/unit'
require 'de'
require 'de/boolean'

class DeBooleanAndTest < Test::Unit::TestCase

  def test_constructor
    assert_nothing_raised(De::Error::AbstractClassObjectCreationError) { De::Boolean::And.new }
    assert_nothing_raised(De::Error::AbstractClassObjectCreationError) { De::Boolean::And.new([De::Boolean::Operand.new('some name', true)]) }
  end

  def test_add
    and1 = De::Boolean::And.new
    operand1 = De::Boolean::Operand.new('some name', true)

    and1 << operand1
    assert_equal(2, and1.size)

    and2 = De::Boolean::And.new
    and1 << and2
    assert_equal(3, and1.size)
  end

  def test_evaluate
    and1 = De::Boolean::And.new
    operand_true1 = De::Boolean::Operand.new('some name', true)
    operand_true2 = De::Boolean::Operand.new('second name', true)
    operand_false1 = De::Boolean::Operand.new('third name', false)
    operand_false2 = De::Boolean::Operand.new('fourth name', false)

    and1 << operand_true1
    and1 << operand_true2
    assert_equal(true, and1.evaluate)

    and2 = De::Boolean::And.new
    and2 << operand_true1
    and2 << operand_false1
    assert_equal(false, and2.evaluate)

    and3 = De::Boolean::And.new([operand_false1, operand_false2])
    assert_equal(false, and3.evaluate)

    and1 << and3
    assert_equal(false, and1.evaluate)

    and4 = De::Boolean::And.new([operand_true1, operand_true2])
    and1 << and4
    assert_equal(false, and1.evaluate)
  end

end
