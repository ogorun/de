require 'test/unit'
require 'de'
require 'de/sunspot_solr'

class DeSunspotSolrAndTest < Test::Unit::TestCase
  include De::SunspotSolr

  def test_constructor
    assert_nothing_raised(De::Error::AbstractClassObjectCreationError) { And.new }
    assert_nothing_raised(De::Error::AbstractClassObjectCreationError) { And.new([SunspotOperand.new('some name', :client_id, :equal_to, 42)]) }
  end

  def test_equal
    a = And.new
    b = And.new
    c = Or.new
    assert(a == b)
    assert(a != c)

    d = And.new([EqualTo.new(:client_id, 42), GreaterThan.new(:price, 200)])
    e = And.new([EqualTo.new(:client_id, 42), GreaterThan.new(:price, 200)])
    f = And.new([GreaterThan.new(:price, 200), EqualTo.new(:client_id, 42)])
    g = And.new([GreaterThan.new(:price, 200), EqualTo.new(:client_id, 42), Without.new(:products_group_id, 188)])
    assert(d == e)
    assert(d == f)
    assert(e != g)

    a << d
    b << f
    assert(a == b)

    h = And.new
    h << g
    assert(a != h)
  end

  def test_add
    and1 = And.new
    operand1 = SunspotOperand.new('some name', :client_id, :eaual_to, 42)

    result = and1 << operand1
    assert_equal(2, and1.size)
    assert_equal(operand1, result)

    operand2 = SunspotOperand.new('some name 2', :client_id, :eaual_to, 42)
    result = and1 << operand2
    assert_equal(2, and1.size)
    assert(result === operand1)

    and2 = And.new
    and1 << and2
    assert_equal(3, and1.size)

    and3 = And.new
    and4 = And.new([EqualTo.new(:client_id, 42), GreaterThan.new(:price, 200)])
    and5 = And.new([GreaterThan.new(:price, 200), EqualTo.new(:client_id, 42)])
    or1 = Or.new([EqualTo.new(:client_id, 42), GreaterThan.new(:price, 200)])

    and3 << and4
    assert_equal(4, and3.size)
    assert_equal(1, and3.children.size)
    assert_equal(and4, and3.first_child)

    result = and3 << and5
    assert(and4 === result)
    assert_equal(4, and3.size)
    assert_equal(1, and3.children.size)
    assert_equal(and4, and3.first_child)
    
    result = and3 << or1
    assert(or1 === result)
    assert_equal(7, and3.size)
    assert_equal(2, and3.children.size)
    assert_equal(or1, and3.children[1])
  end

  def test_evaluate
    and1 = And.new
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


    and1 << client_operand
    and1 << name_operand
    assert_raise (De::Error::InvalidExpressionError) { and1.evaluate }

    search << and1
    assert_nothing_raised(De::Error::InvalidExpressionError) {
      assert_equal("all_of do with(:client_id).equal_to(42) with(:name).equal_to('some name') end", and1.evaluate.gsub(/\s+/, ' '))
    }
    
    and1 << price_operand
    assert_equal("all_of do with(:client_id).equal_to(42) with(:name).equal_to('some name') dynamic(:int_params) do with(:price).greater_than(100) end end", and1.evaluate.gsub(/\s+/, ' '))

    and2 = And.new
    and2 << name2_operand
    and1 << and2
    assert_equal("all_of do with(:name).equal_to('some name 2') end", and2.evaluate.gsub(/\s+/, ' '))
    assert_equal("all_of do with(:client_id).equal_to(42) with(:name).equal_to('some name') dynamic(:int_params) do with(:price).greater_than(100) end all_of do with(:name).equal_to('some name 2') end end", and1.evaluate.gsub(/\s+/, ' '))

  end

end
