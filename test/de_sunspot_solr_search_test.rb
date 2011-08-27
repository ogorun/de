require 'test/unit'
require 'de'
require 'de/sunspot_solr'

class DeSunspotSolrSearchTest < Test::Unit::TestCase
  include De::SunspotSolr
#  fixtures :clients
#  fixtures :products

  def setup
    @search = Search.new('search_product', 'Product', {
      :properties => {
        :client_id => {:type => :integer, :dynamic => false},
        :name => {:type => :string, :dynamic => false},
        :price => {:type => :integer, :dynamic => true}
      },
      :dynamics => {:integer => :int_params, :string => :string_params, :time => :time_params, :text => :string_params}
    })
  end

  def test_constructor
    assert_nothing_raised(De::Error::AbstractClassObjectCreationError) {
      search = Search.new('search_product', 'Product', {
        :properties => {
          :client_id => {:type => :integer, :dynamic => false},
          :name => {:type => :string, :dynamic => false},
          :price => {:type => :integer, :dynamic => true}
        },
        :dynamics => {:integer => :int_params, :string => :string_params, :time => :time_params, :text => :string_params}
      })
      assert_equal(1, search.size, "No child noDes should be adDed")
      assert_equal('search_product', search.name)
      assert_equal('Product', search.klass)
    }
    
    assert_nothing_raised(De::Error::AbstractClassObjectCreationError) {
      operand = EqualTo.new(:client_id, 44)
      search = Search.new('search_product', 'Product', {
        :properties => {
          :client_id => {:type => :integer, :dynamic => false},
          :name => {:type => :string, :dynamic => false},
          :price => {:type => :integer, :dynamic => true}
        },
        :dynamics => {:integer => :int_params, :string => :string_params, :time => :time_params, :text => :string_params}
      }, [operand])
      assert_equal(2, search.size, "operand should be adDed as child noDe")
      assert_equal(operand, search.first_child)
    }
  end

  def test_equal
    options = {
        :properties => {
          :client_id => {:type => :integer, :dynamic => false},
          :name => {:type => :string, :dynamic => false},
          :price => {:type => :integer, :dynamic => true}
        },
        :dynamics => {:integer => :int_params, :string => :string_params, :time => :time_params, :text => :string_params}
    }
    sa = Search.new('a', 'Product', options)
    sb = Search.new('a', 'Product', options)
    assert_equal(sa, sb)

    sa << EqualTo.new(:client_id, 42)
    sb << EqualTo.new(:client_id, 42)
    assert_equal(sa, sb)

    sb << GreaterThan.new(:price, 200)
    assert(sa != sb)

    sc = Search.new('c', 'Product', options, [EqualTo.new(:client_id, 42), GreaterThan.new(:price, 200)])
    sd = Search.new('d', 'Product', options, [EqualTo.new(:client_id, 42), GreaterThan.new(:price, 200)])
    se = Search.new('e', 'Product', options, [GreaterThan.new(:price, 200), EqualTo.new(:client_id, 42)])
    sf = Search.new('f', 'Product', options, [GreaterThan.new(:price, 200), EqualTo.new(:client_id, 42), Without.new(:products_group_id, 188)])
    assert_equal(sc, sd)
    assert_equal(sc, se)
    assert(sc != sf)

    sg = Search.new('g', 'Product', options, [Or.new([EqualTo.new(:client_id, 42), GreaterThan.new(:price, 200)])])
    sh = Search.new('h', 'Product', options, [Or.new([GreaterThan.new(:price, 200), EqualTo.new(:client_id, 42)])])
    si = Search.new('h', 'Product', options, [And.new([GreaterThan.new(:price, 200), EqualTo.new(:client_id, 42)])])
    assert_equal(sg, sh)
    assert(sg != si)
  end

  def test_add
    operand = EqualTo.new(:client_id, 44)
    operator = And.new

    assert_nothing_raised(De::Error::TypeError) {
      result = @search << operand
      assert_equal(2, @search.size)
      assert(operand === result)
      assert_equal(operand, @search.first_child)

      @search << operator
      assert_equal(3, @search.size)
      assert_equal(operator, @search.children[1])

      operand2 = EqualTo.new(:client_id, 44)
      result = @search << operand2
      assert_equal(3, @search.size)
      assert_equal(operand2, result)
      assert(operand === result)
    }

    assert_raise(De::Error::TypeError) {
      @search << "some string"
    }
    
    options = {
        :properties => {
          :client_id => {:type => :integer, :dynamic => false},
          :name => {:type => :string, :dynamic => false},
          :price => {:type => :integer, :dynamic => true}
        },
        :dynamics => {:integer => :int_params, :string => :string_params, :time => :time_params, :text => :string_params}
    }
    sa = Search.new('a', 'Product', options)
    or1 = Or.new([EqualTo.new(:client_id, 42), GreaterThan.new(:price, 200)])
    or2 = Or.new([GreaterThan.new(:price, 200), EqualTo.new(:client_id, 42)])

    sa << or1
    assert_equal(4, sa.size)
    assert_equal(1, sa.children.size)
    assert_equal(or1, sa.first_child)

    result = sa << or2
    assert(or1 === result)
    assert_equal(4, sa.size)
    assert_equal(1, sa.children.size)
  end

  def test_valid
    assert(@search.valid?)

    operand = EqualTo.new(:client_id, 44)
    operator = And.new

    @search << operand
    assert(@search.valid?)

    @search << operator
    assert(!@search.valid?)
  end

#  def test_evaluate
#    client = clients(:one)
#    product = products(:one)
#
#    Product.reindex
#    operand = EqualTo.new(:client_id, client.id)
#    @search << operand
#
#    sunspot_search = @search.evaluate
#    product_ids = sunspot_search.results.map(&:id)
#
#    assert(product_ids.incluDe?(product.id))
#  end

  def test_union
    search2 = Search.new('search_product2', 'AnotherClass', {
      :properties => {
        :client_id => {:type => :integer, :dynamic => false},
      },
      :dynamics => {:integer => :int_params, :string => :string_params, :time => :time_params, :text => :string_params}
    })
    search3 = @search | search2

    assert_instance_of(Search, search3)
    assert_equal('search_product+search_product2', search3.name)
    assert_equal('Product', search3.klass)
    assert_equal(@search.options, search3.options)
    assert(!search3.has_children?)

    operand = EqualTo.new(:client_id, 44)
    operand2 = EqualTo.new(:client_id, 42)
    search2 << operand
    search2 << operand2
    search3 = @search | search2
    assert(search3.has_children?)
    assert_equal(5, search3.size)
    assert_equal(1, search3.children.length)
    or_operator = search3.first_child
    assert_instance_of(Or, or_operator)
    assert_equal(1, or_operator.children.length)
    and_operator = or_operator.first_child
    assert_instance_of(And, and_operator)
    assert_equal(2, and_operator.children.length)
    assert_equal(operand, and_operator.children[0])
    assert_equal(operand2, and_operator.children[1])

    operand3 = EqualTo.new(:client_id, 43)
    operand4 = EqualTo.new(:client_id, 56)
    @search << operand3
    @search << operand4
    search3 = @search | search2
    assert(search3.has_children?)
    assert_equal(8, search3.size)
    assert_equal(1, search3.children.length)
    or_operator = search3.first_child
    assert_instance_of(Or, or_operator)
    assert_equal(2, or_operator.children.length)
    and_operator1 = or_operator.first_child
    assert_instance_of(And, and_operator1)
    assert_equal(2, and_operator1.children.length)
    assert(!and_operator1[operand.name].nil? && !and_operator1[operand2.name].nil? || !and_operator1[operand3.name].nil? && !and_operator1[operand4.name].nil?)
    and_operator2 = or_operator.children[1]
    assert_instance_of(And, and_operator2)
    assert_equal(2, and_operator2.children.length)
    assert(!and_operator2[operand.name].nil? && !and_operator2[operand2.name].nil? || !and_operator2[operand3.name].nil? && !and_operator2[operand4.name].nil?)
  end

  def test_intersection
    search2 = Search.new('search_product2', 'AnotherClass', {
      :properties => {
        :client_id => {:type => :integer, :dynamic => false},
      },
      :dynamics => {:integer => :int_params, :string => :string_params, :time => :time_params, :text => :string_params}
    })
    search3 = @search & search2

    assert_instance_of(Search, search3)
    assert_equal('search_product+search_product2', search3.name)
    assert_equal('Product', search3.klass)
    assert_equal(@search.options, search3.options)
    assert(!search3.has_children?)

    operand = EqualTo.new(:client_id, 44)
    operand2 = EqualTo.new(:client_id, 42)
    search2 << operand
    search2 << operand2
    search3 = @search & search2
    assert(search3.has_children?)
    assert_equal(3, search3.size)
    assert_equal(2, search3.children.length)
    assert(!search3[operand.name].nil? && !search3[operand2.name].nil?)

    operand3 = EqualTo.new(:client_id, 43)
    operand4 = EqualTo.new(:client_id, 56)
    or_operator = Or.new([operand3, operand4])
    @search << or_operator
    search3 = @search & search2
    assert(search3.has_children?)
    assert_equal(6, search3.size)
    assert_equal(3, search3.children.length)
    assert(!search3[operand.name].nil? && !search3[operand2.name].nil? && !search3[or_operator.name].nil?)
    assert_equal(2, search3[or_operator.name].children.length)
  end

end
