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
        Search.new("#{@name}+#{obj.name}", @klass, @options, [self.children, obj.children].flatten)
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
        expression_content << SunspotSolr::And.new(self.children) if self.has_children?
        expression_content << SunspotSolr::And.new(obj.children) if obj.has_children?

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
      # params<Hash>:: optional parameters hash
      #   Supported hash keys:
      #     :page - gives page for paging.
      #       Number of results per page is defined by @option[:per_page] parameter
      #       Default values: page - 1, per_page - 10000
      #
      # === Output
      #
      # Sunspot Search object
      # built on its current tree operators and operands
      #
      def evaluate(params = nil)
        super

        page = params && params[:page] ? params[:page] : 1
        per_page = @options[:per_page] || 10000

        search_string = "Sunspot.search(#{Kernel.const_get(@klass)}) do
          #{children.map {|child| child.evaluate + "\n" } }

          paginate(:page => #{page}, :per_page => #{per_page})
        end"

        instance_eval search_string
      end
    end
  end
end