require 'test/unit'
require 'de'
require 'de/sunspot_solr'

class DeSunspotSolrOrTest < Test::Unit::TestCase
  include De::SunspotSolr
  
  def test_constructor
    assert_nothing_raised(De::Error::AbstractClassObjectCreationError) { Or.new }
    assert_nothing_raised(De::Error::AbstractClassObjectCreationError) { Or.new([SunspotOperand.new('some name', :client_id, :equal_to, 42)]) }
  end

  def test_add
    or1 = Or.new
    operand1 = SunspotOperand.new('some name', :client_id, :equal_to, 42)

    or1 << operand1
    assert_equal(2, or1.size)

    or2 = Or.new
    or1 << or2
    assert_equal(3, or1.size)
  end

  def test_evaluate
    or1 = Or.new
    client_operand = EqualTo.new(:client_id, 42)
    name_operand = SunspotOperand.new('name', :name, :equal_to, 'some name')
    price_operand = SunspotOperand.new('price', :price, :greater_than, 100)
    name2_operand = SunspotOperand.new('name2', :name, :equal_to, 'some name 2')
    search = Search.new('search_product', 'Product', {
      :properties => {
        :client_id => {:type => :integer, :dynamic => false},
        :name => {:type => :string, :dynamic => false},
        :price => {:type => :integer, :dynamic => true}
      },
      :dynamics => {:integer => :int_params, :string => :string_params, :time => :time_params, :text => :string_params}
    })


    or1 << client_operand
    or1 << name_operand
    assert_raise (De::Error::InvalidExpressionError) { or1.evaluate }

    search << or1
    assert_nothing_raised(De::Error::InvalidExpressionError) {
      assert_equal("any_of do with(:client_id).equal_to(42) with(:name).equal_to('some name') end", or1.evaluate.gsub(/\s+/, ' '))
    }
    
    or1 << price_operand
    assert_equal("any_of do with(:client_id).equal_to(42) with(:name).equal_to('some name') dynamic(:int_params) do with(:price).greater_than(100) end end", or1.evaluate.gsub(/\s+/, ' '))

    and1 = And.new
    and1 << name2_operand
    or1 << and1
    assert_equal("all_of do with(:name).equal_to('some name 2') end", and1.evaluate.gsub(/\s+/, ' '))
    assert_equal("any_of do with(:client_id).equal_to(42) with(:name).equal_to('some name') dynamic(:int_params) do with(:price).greater_than(100) end all_of do with(:name).equal_to('some name 2') end end", or1.evaluate.gsub(/\s+/, ' '))

  end

end
