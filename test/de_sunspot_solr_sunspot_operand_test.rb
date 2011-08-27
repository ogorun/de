require 'test/unit'
require 'de'
require 'de/sunspot_solr'

class DeSunspotSolrSunspotOperandTest < Test::Unit::TestCase
  include De::SunspotSolr

  def test_constructor
    assert_nothing_raised(De::Error::AbstractClassObjectCreationError) { SunspotOperand.new('some name', :client_id, :equal_to, 44) }

    operand = SunspotOperand.new('some name', :client_id, :equal_to, 44)
    assert_equal('some name', operand.name)
    assert_equal('client_id', operand.content)
  end

  def test_add
    operand = SunspotOperand.new('some name', :client_id, :equal_to, 44)
    operand2 = SunspotOperand.new('some name 2', :client_id, :eaual_to, 42)

    assert_raise(De::Error::TypeError) { operand << operand2 }
  end

  def test_equal
    operand = SunspotOperand.new('some name', :client_id, :equal_to, 44)
    operand2 = SunspotOperand.new('some name', :client_id, :equal_to, 44)
    operand3 = SunspotOperand.new('some name 2', :client_id, :equal_to, 44)
    operand4 = SunspotOperand.new('some name', :client_id, :equal_to, 42)
    operand5 = SunspotOperand.new('some name', :products_group_id, :equal_to, 44)
    operand6 = SunspotOperand.new('some name', :client_id, :less_than, 44)

    assert(operand == operand2)
    assert(operand2 == operand)
    assert(operand == operand3)
    assert(operand != operand4)
    assert(operand != operand5)
    assert(operand != operand6)
  end

  def test_valid?
    operand = SunspotOperand.new('some name', :client_id, :not_existent_operand, 44)
    assert_equal(false, operand.valid?, 'Operand with unknown @operand field should be invalid')

    operand = SunspotOperand.new('some name', :client_id, :equal_to, 44)
    assert_equal(false, operand.valid?, 'Operand without (valid) root should be invalid')

    operand2 = SunspotOperand.new('some name 2', :title, :equal_to, 44)
    search = Search.new('search_product', 'Product', {
      :properties => {
        :client_id => {:type => :integer, :dynamic => false},
        :name => {:type => :string, :dynamic => false},
        :price => {:type => :integer, :dynamic => true}
      },
      :dynamics => {:integer => :int_params, :string => :string_params, :time => :time_params, :text => :string_params}
    })
    search << operand
    search << operand2
    assert_equal(false, operand2.valid?, 'Operand not registered in root should be invalid')
    assert_equal(true, operand.valid?, 'Operand registered in root should be valid')
    
  end

  def test_evaluate_integer
    search = Search.new('search_product', 'Product', {
      :properties => {
        :client_id => {:type => :integer, :dynamic => false},
        :group_id => {:type => :integer, :dynamic => true},
      },
      :dynamics => {:integer => :int_params}
    })

    op1 = SunspotOperand.new('op1', :client_id, :equal_to, 44)
    search << op1
    assert_equal("with(:client_id).equal_to(44)",op1.evaluate.gsub(/\s+/, ' '))

    op2 = SunspotOperand.new('op2', :client_id, :between, 42..44)
    search << op2
    assert_equal("with(:client_id).between(42..44)",op2.evaluate.gsub(/\s+/, ' '))

    op3 = SunspotOperand.new('op3', :client_id, :any_of, [42, 43, 44])
    search << op3
    assert_equal("with(:client_id).any_of([42,43,44])",op3.evaluate.gsub(/\s+/, ' '))

    op4 = SunspotOperand.new('op4', :group_id, :greater_than, 188)
    search << op4
    assert_equal("dynamic(:int_params) do with(:group_id).greater_than(188) end",op4.evaluate.gsub(/\s+/, ' '))

    op5 = SunspotOperand.new('op5', :group_id, :between, 200..250)
    search << op5
    assert_equal("dynamic(:int_params) do with(:group_id).between(200..250) end",op5.evaluate.gsub(/\s+/, ' '))

    op6 = SunspotOperand.new('op6', :group_id, :any_of, [42, 43, 44])
    search << op6
    assert_equal("dynamic(:int_params) do with(:group_id).any_of([42,43,44]) end", op6.evaluate.gsub(/\s+/, ' '))
  end

  def test_evaluate_float
    search = Search.new('search_product', 'Product', {
      :properties => {
        :client_id => {:type => :float, :dynamic => false},
        :group_id => {:type => :float, :dynamic => true},
      },
      :dynamics => {:float => :float_params}
    })

    op1 = SunspotOperand.new('op1', :client_id, :less_than, 44.0)
    search << op1
    assert_equal("with(:client_id).less_than(44.0)",op1.evaluate.gsub(/\s+/, ' '))

    op2 = SunspotOperand.new('op2', :client_id, :between, 42.0..44.0)
    search << op2
    assert_equal("with(:client_id).between(42.0..44.0)",op2.evaluate.gsub(/\s+/, ' '))

    op3 = SunspotOperand.new('op3', :client_id, :any_of, [42.0, 43.0, 44.0])
    search << op3
    assert_equal("with(:client_id).any_of([42.0,43.0,44.0])",op3.evaluate.gsub(/\s+/, ' '))

    op4 = SunspotOperand.new('op4', :group_id, :greater_than, 188.0)
    search << op4
    assert_equal("dynamic(:float_params) do with(:group_id).greater_than(188.0) end",op4.evaluate.gsub(/\s+/, ' '))

    op5 = SunspotOperand.new('op5', :group_id, :between, 200..250)
    search << op5
    assert_equal("dynamic(:float_params) do with(:group_id).between(200.0..250.0) end",op5.evaluate.gsub(/\s+/, ' '))

    op6 = SunspotOperand.new('op6', :group_id, :any_of, [42, 43.4, 44])
    search << op6
    assert_equal("dynamic(:float_params) do with(:group_id).any_of([42.0,43.4,44.0]) end", op6.evaluate.gsub(/\s+/, ' '))
  end

  def test_evaluate_time
    search = Search.new('search_product', 'Product', {
      :properties => {
        :start_date => {:type => :time, :dynamic => false},
        :end_date => {:type => :time, :dynamic => true},
      },
      :dynamics => {:time => :time_params}
    })

    now = Time.now
    tomorrow = now + 1.day

    op1 = SunspotOperand.new('op1', :start_date, :equal_to, now)
    search << op1
    assert_equal("with(:start_date).equal_to('#{now.to_s(:db)}')",op1.evaluate.gsub(/\s+/, ' '))

    op2 = SunspotOperand.new('op2', :start_date, :between, now..tomorrow)
    search << op2
    assert_equal("with(:start_date).between('#{now.to_s(:db)}'..'#{tomorrow.to_s(:db)}')",op2.evaluate.gsub(/\s+/, ' '))

    op3 = SunspotOperand.new('op3', :start_date, :any_of, [now, tomorrow])
    search << op3
    assert_equal("with(:start_date).any_of(['#{now.to_s(:db)}','#{tomorrow.to_s(:db)}'])",op3.evaluate.gsub(/\s+/, ' '))

    op4 = SunspotOperand.new('op4', :end_date, :greater_than, now)
    search << op4
    assert_equal("dynamic(:time_params) do with(:end_date).greater_than('#{now.to_s(:db)}') end",op4.evaluate.gsub(/\s+/, ' '))

    op5 = SunspotOperand.new('op5', :end_date, :between, now..tomorrow)
    search << op5
    assert_equal("dynamic(:time_params) do with(:end_date).between('#{now.to_s(:db)}'..'#{tomorrow.to_s(:db)}') end",op5.evaluate.gsub(/\s+/, ' '))

    op6 = SunspotOperand.new('op6', :end_date, :any_of, [now, tomorrow])
    search << op6
    assert_equal("dynamic(:time_params) do with(:end_date).any_of(['#{now.to_s(:db)}','#{tomorrow.to_s(:db)}']) end", op6.evaluate.gsub(/\s+/, ' '))
  end

  def test_evaluate_string
    search = Search.new('search_product', 'Product', {
      :properties => {
        :name => {:type => :string, :dynamic => false},
        :title => {:type => :string, :dynamic => true},
      },
      :dynamics => {:string => :string_params}
    })

    name = 'some name'
    name2 = 'another name'

    op1 = SunspotOperand.new('op1', :name, :equal_to, name)
    search << op1
    assert_equal("with(:name).equal_to('#{name}')",op1.evaluate.gsub(/\s+/, ' '))

    op2 = SunspotOperand.new('op2', :name, :between, 'AB'..'AC')
    search << op2
    assert_equal("with(:name).between('AB'..'AC')",op2.evaluate.gsub(/\s+/, ' '))

    op3 = SunspotOperand.new('op3', :name, :any_of, [name, name2])
    search << op3
    assert_equal("with(:name).any_of(['#{name}','#{name2}'])",op3.evaluate.gsub(/\s+/, ' '))

    op4 = SunspotOperand.new('op4', :title, :less_than, name)
    search << op4
    assert_equal("dynamic(:string_params) do with(:title).less_than('#{name}') end",op4.evaluate.gsub(/\s+/, ' '))

    op5 = SunspotOperand.new('op5', :title, :between, 'AB'..'AC')
    search << op5
    assert_equal("dynamic(:string_params) do with(:title).between('AB'..'AC') end",op5.evaluate.gsub(/\s+/, ' '))

    op6 = SunspotOperand.new('op6', :title, :any_of, [name, name2])
    search << op6
    assert_equal("dynamic(:string_params) do with(:title).any_of(['#{name}','#{name2}']) end", op6.evaluate.gsub(/\s+/, ' '))
  end


  def test_evaluate_text
    search = Search.new('search_product', 'Product', {
      :properties => {
        :name => {:type => :text, :dynamic => false},
        :title => {:type => :text, :dynamic => true},
      },
      :dynamics => {:text => :string_params}
    })

    name = 'some name'
    name2 = 'another name'

    op1 = SunspotOperand.new('op1', :name, :equal_to, name)
    search << op1
    assert_equal("with(:name).equal_to('#{name}')",op1.evaluate.gsub(/\s+/, ' '))

    op2 = SunspotOperand.new('op2', :name, :between, 'AB'..'AC')
    search << op2
    assert_equal("with(:name).between('AB'..'AC')",op2.evaluate.gsub(/\s+/, ' '))

    op3 = SunspotOperand.new('op3', :name, :any_of, [name, name2])
    search << op3
    assert_equal("with(:name).any_of(['#{name}','#{name2}'])",op3.evaluate.gsub(/\s+/, ' '))

    op4 = SunspotOperand.new('op4', :title, :less_than, name)
    search << op4
    assert_equal("dynamic(:string_params) do with(:title).less_than('#{name}') end",op4.evaluate.gsub(/\s+/, ' '))

    op5 = SunspotOperand.new('op5', :title, :between, 'AB'..'AC')
    search << op5
    assert_equal("dynamic(:string_params) do with(:title).between('AB'..'AC') end",op5.evaluate.gsub(/\s+/, ' '))

    op6 = SunspotOperand.new('op6', :title, :any_of, [name, name2])
    search << op6
    assert_equal("dynamic(:string_params) do with(:title).any_of(['#{name}','#{name2}']) end", op6.evaluate.gsub(/\s+/, ' '))
  end

  def test_interval_operand
    search = Search.new('search_product', 'Product', {
      :properties => {
        :start_date => {:type => :time, :dynamic => false},
        :name => {:type => :string, :dynamic => false}
      },
      :dynamics => {:time => :time_params}
    })

    now = Time.now

    op1 = IntervalSunspotOperand.new('op1', :start_date, :equal_to, 2)
    search << op1
    assert_equal("with(:start_date).equal_to('#{(now + 2.days).to_s(:db)}')", op1.evaluate.gsub(/\s+/, ' '))
    
    op2 = IntervalSunspotOperand.new('op2', :start_date, :between, 1..2)
    search << op2
    assert_equal("with(:start_date).between('#{(now + 1.day).to_s(:db)}'..'#{(now + 2.days).to_s(:db)}')",op2.evaluate.gsub(/\s+/, ' '))

    op3 = IntervalSunspotOperand.new('op3', :start_date, :any_of, [1,2])
    search << op3
    assert_equal("with(:start_date).any_of(['#{(now + 1.day).to_s(:db)}','#{(now + 2.days).to_s(:db)}'])",op3.evaluate.gsub(/\s+/, ' '))

    op4 = IntervalSunspotOperand.new('op4', :name, :less_than, 'test')
    assert(!op4.valid?)

    op5 = IntervalSunspotOperand.new('op5', :start_date, :between, 1...3)
    search << op5
    assert_equal("with(:start_date).between('#{(now + 1.day).to_s(:db)}'...'#{(now + 3.days).to_s(:db)}')",op5.evaluate.gsub(/\s+/, ' '))

  end

  def test_EqualTo
    search = Search.new('search_product', 'Product', {
      :properties => {
        :name => {:type => :string, :dynamic => false}
      },
      :dynamics => {}
    })

    op = EqualTo.new(:name, 'test')
    search << op
    assert_equal("with(:name).equal_to('test')", op.evaluate.gsub(/\s+/, ' '))
  end

  def test_Without
    search = Search.new('search_product', 'Product', {
      :properties => {
        :name => {:type => :string, :dynamic => false}
      },
      :dynamics => {}
    })

    op = Without.new(:name, 'test')
    search << op
    assert_equal("without(:name, 'test')", op.evaluate.gsub(/\s+/, ' '))
  end

  def test_GreaterThan
    search = Search.new('search_product', 'Product', {
      :properties => {
        :start_date => {:type => :time, :dynamic => false}
      },
      :dynamics => {}
    })

    now = Time.now

    op = GreaterThan.new(:start_date, now)
    search << op
    assert_equal("with(:start_date).greater_than('#{now.to_s(:db)}')", op.evaluate.gsub(/\s+/, ' '))
  end

  def test_LessThan
    search = Search.new('search_product', 'Product', {
      :properties => {
        :start_date => {:type => :time, :dynamic => false}
      },
      :dynamics => {}
    })

    now = Time.now

    op = LessThan.new(:start_date, now)
    search << op
    assert_equal("with(:start_date).less_than('#{now.to_s(:db)}')", op.evaluate.gsub(/\s+/, ' '))
  end

  def test_GreaterThanOrEqual
    search = Search.new('search_product', 'Product', {
      :properties => {
        :start_date => {:type => :time, :dynamic => false}
      },
      :dynamics => {}
    })

    now = Time.now

    op = GreaterThanOrEqual.new(:start_date, now)
    search << op
    assert_equal("any_of do with(:start_date).greater_than('#{now.to_s(:db)}') with(:start_date, '#{now.to_s(:db)}') end", op.evaluate.gsub(/\s+/, ' '))
  end

  def test_LessThanOrEqual
    search = Search.new('search_product', 'Product', {
      :properties => {
        :start_date => {:type => :time, :dynamic => false}
      },
      :dynamics => {}
    })

    now = Time.now

    op = LessThanOrEqual.new(:start_date, now)
    search << op
    assert_equal("any_of do with(:start_date).less_than('#{now.to_s(:db)}') with(:start_date, '#{now.to_s(:db)}') end", op.evaluate.gsub(/\s+/, ' '))
  end

  def test_Between
    search = Search.new('search_product', 'Product', {
      :properties => {
        :start_date => {:type => :time, :dynamic => false}
      },
      :dynamics => {}
    })

    now = Time.now
    tomorrow = now + 1.day

    op = Between.new(:start_date, now..tomorrow)
    search << op
    assert_equal("with(:start_date).between('#{now.to_s(:db)}'..'#{tomorrow.to_s(:db)}')", op.evaluate.gsub(/\s+/, ' '))
  end

  def test_AnyOf
    search = Search.new('search_product', 'Product', {
      :properties => {
        :start_date => {:type => :time, :dynamic => false}
      },
      :dynamics => {}
    })

    now = Time.now
    tomorrow = now + 1.day

    op = AnyOf.new(:start_date, [now,tomorrow])
    search << op
    assert_equal("with(:start_date).any_of(['#{now.to_s(:db)}','#{tomorrow.to_s(:db)}'])", op.evaluate.gsub(/\s+/, ' '))
  end


  def test_IntervalFromNowEqualTo
    search = Search.new('search_product', 'Product', {
      :properties => {
        :start_date => {:type => :time, :dynamic => false}
      },
      :dynamics => {}
    })

    today = Date.today
    op = IntervalFromNowEqualTo.new(:start_date, 1)
    search << op
    assert_match(/^with\(:start_date\)\.equal_to\('#{(today + 1.day).to_s(:db)}/, op.evaluate.gsub(/\s+/, ' '))
  end

  def test_IntervalFromNowWithout
    search = Search.new('search_product', 'Product', {
      :properties => {
        :start_date => {:type => :time, :dynamic => false}
      },
      :dynamics => {}
    })

    today = Date.today
    op = IntervalFromNowWithout.new(:start_date, 1)
    search << op
    assert_match(/^without\(:start_date, '#{(today + 1.day).to_s(:db)}/, op.evaluate.gsub(/\s+/, ' '))
  end

  def test_IntervalFromNowGreaterThan
    search = Search.new('search_product', 'Product', {
      :properties => {
        :start_date => {:type => :time, :dynamic => false}
      },
      :dynamics => {}
    })

    today = Date.today
    op = IntervalFromNowGreaterThan.new(:start_date, 1)
    search << op
    assert_match(/^with\(:start_date\).greater_than\('#{(today + 1.day).to_s(:db)}/, op.evaluate.gsub(/\s+/, ' '))
  end

  def test_IntervalFromNowLessThan
    search = Search.new('search_product', 'Product', {
      :properties => {
        :start_date => {:type => :time, :dynamic => false}
      },
      :dynamics => {}
    })

    today = Date.today
    op = IntervalFromNowLessThan.new(:start_date, 1)
    search << op
    assert_match(/^with\(:start_date\).less_than\('#{(today + 1.day).to_s(:db)}/, op.evaluate.gsub(/\s+/, ' '))
  end

  def test_IntervalFromNowGreaterThanOrEqual
    search = Search.new('search_product', 'Product', {
      :properties => {
        :start_date => {:type => :time, :dynamic => false}
      },
      :dynamics => {}
    })

    today = Date.today
    op = IntervalFromNowGreaterThanOrEqual.new(:start_date, 1)
    search << op
    assert_match(/^any_of do with\(:start_date\).greater_than\('#{(today + 1.day).to_s(:db)} [\d\:]+'\) with\(:start_date, '#{(today + 1.day).to_s(:db)} [\d\:]+'\) end$/, op.evaluate.gsub(/\s+/, ' '))
  end

  def test_IntervalFromNowLessThanOrEqual
    search = Search.new('search_product', 'Product', {
      :properties => {
        :start_date => {:type => :time, :dynamic => false}
      },
      :dynamics => {}
    })

    today = Date.today

    op = IntervalFromNowLessThanOrEqual.new(:start_date, 1)
    search << op
    assert_match(/^any_of do with\(:start_date\).less_than\('#{(today + 1.day).to_s(:db)} [\d\:]+'\) with\(:start_date, '#{(today + 1.day).to_s(:db)} [\d\:]+'\) end/, op.evaluate.gsub(/\s+/, ' '))
  end

  def test_IntervalFromNowBetween
    search = Search.new('search_product', 'Product', {
      :properties => {
        :start_date => {:type => :time, :dynamic => false}
      },
      :dynamics => {}
    })

    today = Date.today
    tomorrow = today + 1.day

    op = IntervalFromNowBetween.new(:start_date, 0..1)
    search << op
    assert_match(/^with\(:start_date\).between\('#{today.to_s(:db)} [\d\:]+'..'#{tomorrow.to_s(:db)} [\d\:]+'\)/, op.evaluate.gsub(/\s+/, ' '))
  end

  def test_IntervalFromNowAnyOf
    search = Search.new('search_product', 'Product', {
      :properties => {
        :start_date => {:type => :time, :dynamic => false}
      },
      :dynamics => {}
    })

    today = Date.today
    tomorrow = today + 1.day

    op = IntervalFromNowAnyOf.new(:start_date, [0,1])
    search << op
    assert_match(/^with\(:start_date\)\.any_of\(\['#{today.to_s(:db)} [\d\:]+','#{tomorrow.to_s(:db)} [\d\:]+'\]\)/, op.evaluate.gsub(/\s+/, ' '))
  end
end
