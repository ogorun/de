require 'test/unit'
require 'de'

class DeOperandTest < Test::Unit::TestCase

  class SomeOperand < De::Operand; end
  
  def test_constructor
    assert_raise(De::Error::AbstractClassObjectCreationError, "Cannot create operator object") { De::Operand.new('some name', 'some value') }

    assert_nothing_raised(De::Error::AbstractClassObjectCreationError) {
      operand =  SomeOperand.new('some name', 'some value')
      assert_equal('some name', operand.name)
      assert_equal('some value', operand.content)
    }
  end

  def test_add
    operand =  SomeOperand.new('some name', 'some value')
    operand2 =  SomeOperand.new('another name', 'another value')

    assert_raise(De::Error::TypeError, "Cannot add child to operand") { operand << operand2 }
  end

  def test_evaluate
    operand =  SomeOperand.new('some name', 'some value')
    assert_raise(De::Error::MethodShouldBeOverridenByExtendingClassError, "evlauate method should raise Exception") { operand.evaluate }
  end
end
