require 'test/unit'
require 'de'
require 'de/boolean'

class DeBooleanOperatorTest < Test::Unit::TestCase

  class SomeOperator < De::Boolean::BooleanOperator; end
  class SomeOperator < De::Boolean::BooleanOperator; end
  class NotSuitableOperand < De::Operand; end

  def test_constructor
    assert_raise(De::Error::AbstractClassObjectCreationError) { De::Boolean::BooleanOperator.new('first', 'some operator') }
    assert_nothing_raised(De::Error::AbstractClassObjectCreationError) { SomeOperator.new('some name', 'some operator') }
  end

  def test_to_hash
    and1 = De::Boolean::And.new
    operand1 = De::Boolean::Operand.new('some name', true)

    and1 << operand1
    assert_equal({
        :class => "De::Boolean::And",
        :children => [{:class=>"De::Boolean::Operand", :children=>[], :name=>"some name", :content=>true}],
        :name => and1.name,
        :content => "AND"},
      and1.to_hash)
  end

  def test_load
    and1 = De::Boolean::And.new
    operand1 = De::Boolean::Operand.new('some name', true)

    and1 << operand1
    hsh = and1.to_hash
    assert_equal(and1, De::Expression.load(hsh))


  end

  def test_to_s
    and1 = De::Boolean::And.new
    operand1 = De::Boolean::Operand.new('some name', true)

    and1 << operand1
    assert_equal('AND(true)', and1.to_s)
  end

  def test_add
    operator = SomeOperator.new('first', 'some operator')
    operator2 = SomeOperator.new('second', 'some operator')
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
