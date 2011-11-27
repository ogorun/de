#
# De::SunspotSolr::Search class
#
# De::SunspotSolr module provides engine to build, validate and evaluate dynamic sunspot query to solr
# based on some model.
# It is built as extension of De module
#
# SunspotSolr expression example:
#
# Sunspot.search(Product) do
#   any_of do
#     with(:client_id).equal_to(43)
#     with(:name).equal_to('Name to trace')
#   end
#   with(:update_time).greater_then('15/03/11')
# end
#

require 'de/symmetric_operator'

module De
  module SunspotSolr

    # Marker module included to all module classes 
    # to be able to check that class is inside module
    module SP; end
    
    #
    # Search class
    #
    # Expression extention representing sunspot search
    # Its evaluation returns Sunspot Search object
    # built on its operators and operands tree
    #
    class Search < Expression
      include SP
      include De::SymmetricOperator

      attr_reader :klass, :options

      #
      # Constructor
      # Stores object properties. Adds operands to expression tree
      #
      # === Input
      #
      # name<String>:: arbitrary object name
      # klass<String>:: name of model search is built on
      # options<Hash>:: options specifying model fields properties as they are registered in Solr
      #     Options are used by operands in order to build proper sunspot condition according to property type and static/dynamic nature
      #
      #     Hash has following structure
      #      {
      #        :properties => { <property> => {:type => <type>, :dynamic => <dynamic>}, ... },
      #        :dynamics => { <type> => <dynamic property name>, ... }
      #      }
      #
      #      <type> - type name (symbol)
      #      <dynamic> - true|false
      #      <dynamic property name> - dynamic solr field name (symbol)
      #
      # operands<Array>:: (optional) array of Operand objects.
      #    If given they are added as children to current Search object
      #
      # === Exmaple
      #      search = De::SunspotSolr::Search.new('search_product', 'Product', {
      #          :properties => {
      #            :client_id => {:type => :integer, :dynamic => false},
      #            :name => {:type => :string, :dynamic => false},
      #            :price => {:type => :integer, :dynamic => true}
      #          },
      #          :dynamics => {:integer => :int_params, :string => :string_params, :time => :time_params, :text => :string_params},
      #          :per_page => 30
      #        })
      #
      def initialize(name, klass, options = {}, operands = nil)
        super(name, nil)
        @klass = klass
        @options = options

        unless operands.nil?
          raise Error::TypeError unless operands.is_a?(Array)
          operands.each { |operand| self << operand }
        end
      end

      #
      # Adds operator or operand as a child to Search.
      # Prevents addition of invalid type Object
      #
      # === Input
      #
      # obj<SunspotSolr::Operator|SunspotSolr::Operand>:: object to be added as child one
      #
      # === Output
      #
      # <SunspotSolr::Operator|SunspotSolr::Operand>:: child object
      #
      def <<(obj)
        raise Error::TypeError unless (obj.is_a?(SP))
        children.include?(obj) ? children[children.index(obj)] : super(obj)
      end

      #
      # Equal override
      # Checks objects class, +klass+ property and children equality. Children order is NOT important
      #
      # === Input
      #
      # obj<SunspotSolr::Search>:: object to compare with
      #
      def ==(obj)
        obj.is_a?(Search) && obj.klass == @klass && ((children | obj.children) - (children & obj.children)).length == 0
      end

      #
      # Intersection operator. Reterns new Search object representing intersection of results
      # given by current and input search results
      #
      # === Input
      #
      #  obj<Search>:: search to find intersection with
      #
      # === Output
      #
      #  Search object
      #
      def &(obj)
        children = (self.children + obj.children).collect { |child| child.copy  }
        Search.new("#{@name}+#{obj.name}", @klass, @options, children)
      end

      #
      # Union operator. Reterns new Search object representing unin of results
      # given by current and input search results
      #
      # === Input
      #
      #  obj<Search>:: search to find union with
      #
      # === Output
      #
      #  Search object
      #
      def |(obj)
        expression_content = []
        [self, obj].select { |element| element.has_children? }.each do |element|
          if element.children.length == 1
            if element.first_child.is_a?(De::SunspotSolr::Or)
              element.first_child.children.each { |child| expression_content << child.copy }
            else
              expression_content << element.first_child.copy
            end
          else
            expression_content << SunspotSolr::And.new(element.children.collect { |child| child.copy })
          end
        end

        Search.new("#{@name}+#{obj.name}", @klass, @options, expression_content.length > 0 ? [SunspotSolr::Or.new(expression_content)] : nil)
      end

      #
      # Validator
      #
      # Expression tree is valid in case their children are valid if any
      #
      def valid?
        children.inject(true) {|result, el| result && el.valid?}
      end

      #
      # Evaluator
      #
      # === Input
      # 
      # params<Hash>:: optional parameters hash
      #   Supported hash keys:
      #     :page - gives page for paging (default - 1)
      #     :per_page - gives number of results per page for paging
      #       If not given Number of results per page is defined by @option[:per_page] parameter (default - 10000)
      #     :order_by - hash {<field> => <sorting direction>}, i.e. {:client_id => :desc}
      #
      # === Output
      #
      # Sunspot Search object
      # built on its current tree operators and operands
      #
      def evaluate(params = nil)
        super

        page = params && params[:page] ? params[:page] : 1
        per_page = params && params[:per_page] ? params[:per_page] : @options[:per_page] || 10000
        order_by = params && params[:order_by] ? params[:order_by] : {:id => :asc}

        search_string = %{Sunspot.search(#{Kernel.const_get(@klass)}) do
          #{children.map {|child| child.evaluate }.join("\n") }

          paginate(:page => #{page}, :per_page => #{per_page})
          order_by(:#{order_by.keys[0].to_s}, :#{order_by.values[0].to_s})
        end}

        instance_eval search_string
      end

      #
      # Evaluates expression and returns results of obtained sunspot request
      #
      # === Input
      #
      # params<Hash>:: optional parameters hash passed to evaluate method
      #
      # === Output
      #
      #  <mixed> - object of class @klass Sunspot search is built on
      #
      def results(params = nil)
        evaluate(params).results
      end
      
#      def to_hash
#        children_hash = children.inject({}) { |result, child| result.merge(child.to_hash) }
#        {:options => options, :children => children_hash}
#      end
#
#      class << self
#
#        def load(hash)
#          raise Error::InvalidExpressionError if (hash.keys - [:name, :content, :class, :children]).length > 0
#
#          obj = hash[:class].constantize.send(:new, hash[:name], hash[:content])
#          hash[:children].each { |child| obj << load(child) }
#        end
#      end
    end
  end
end