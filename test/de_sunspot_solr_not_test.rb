require 'test/unit'
require 'de'
require 'de/sunspot_solr'

class DeSunspotSolrNotTest < Test::Unit::TestCase
  include De::SunspotSolr

  def test_constructor
    assert_nothing_raised(De::Error::AbstractClassObjectCreationError) { Not.new }
    assert_nothing_raised(De::Error::AbstractClassObjectCreationError) { Not.new(SunspotOperand.new('some name', :client_id, :equal_to, 42)) }
  end

  def test_add
    not1 = Not.new
    operand1 = SunspotOperand.new('some name', :client_id, :equal_to, 42)

    not1 << operand1
    assert_equal(2, not1.size)

    or1 = Or.new
    operand2 = EqualTo.new(:client_id, 42)

    assert_raise(De::Error::TypeError) { not1 << or1 }
    assert_raise(De::Error::ArgumentNumerError) { not1 << operand2 }
  end

  def test_evaluate
    not1 = Not.new(EqualTo.new(:client_id, 42))
    not2 = Not.new(GreaterThanOrEqual.new(:price, 100))
    search = Search.new('search_product', 'Product', {
      :properties => {
        :client_id => {:type => :integer, :dynamic => false},
        :name => {:type => :string, :dynamic => false},
        :price => {:type => :integer, :dynamic => true}
      },
      :dynamics => {:integer => :int_params, :string => :string_params, :time => :time_params, :text => :string_params}
    })


    search << not1
    assert_nothing_raised(De::Error::InvalidExpressionError) {
      assert_equal("without(:client_id).equal_to(42)", not1.evaluate.gsub(/\s+/, ' '))
    }
    
    search << not2
    assert_equal("dynamic(:int_params) do any_of do without(:price).greater_than(100) without(:price, 100) end end", not2.evaluate.gsub(/\s+/, ' '))
  end

end
