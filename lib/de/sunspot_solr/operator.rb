#
# De::SunspotSolr operator classes: And and Or
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
#   with(:update_time).greater_then('2011-03-15 00:15:00')
# end
#

require 'de/symmetric_operator'

module De
  module SunspotSolr

    # Marker module included to all module classes
    # to be able to check that class is inside module
    module SP; end
    
    class SunspotOperator < Operator
      include De::SunspotSolr::SP
      include De::SymmetricOperator

      def initialize(operator, operands = nil)
        @operator = operator
        super("#{operator}-#{rand(1000)}", operator, operands)
      end

      def evaluate
        super
        "#{@operator} do
          #{children.map { |child| child.evaluate + "\n" } }
        end"
      end
      
      #
      # Adds operator or operand as a child in case equal one doesn't exist already
      # otherwize old one is returned
      #
      # === Input
      #
      # obj<SP>:: object to be added as child one
      #
      # === Output
      #
      # <SP>:: child object
      #
      def <<(obj)
        raise Error::TypeError unless obj.is_a?(SP)
        children.include?(obj) ? children[children.index(obj)] : super(obj)
      end
    end

    #
    # Class representing AND operator for SunspotSolr expression.
    # In resulting Sunspot query it is reflected as all_of block
    #
    class And < SunspotOperator
      
      #
      # Creates And object.
      # Name includes word 'all_of' with random number to avoid TreeNode problem
      # when trying to add children with the same name to a node
      #
      # === Input
      #
      # operands<Array>:: (optional) array of Operand objects.
      #    If given they are added as children to current operator
      #
      def initialize(operands = nil)
        super("all_of", operands)
      end
    end

    class Or < SunspotOperator
      
      #
      # Creates Or object.
      # Name includes word 'any_of' with random number to avoid TreeNode problem
      # when trying to add children with the same name to a node
      #
      # === Input
      #
      # operands<Array>:: (optional) array of Operand objects.
      #    If given they are added as children to current operator
      #
      def initialize(operands = nil)
        super("any_of", operands)
      end
    end

    class Not < SunspotOperator

      #
      # Creates Or object.
      # Name includes word 'any_of' with random number to avoid TreeNode problem
      # when trying to add children with the same name to a node
      #
      # === Input
      #
      # operands<Array>:: (optional) array of Operand objects.
      #    If given they are added as children to current operator
      #
      def initialize(operand = nil)
        super("not", operand ? [operand] : nil)
      end

      #
      # Adds sunspot operand as a child to not operator
      #
      def <<(obj)
        raise Error::TypeError unless obj.is_a?(De::SunspotSolr::SunspotOperand)
        raise Error::ArgumentNumerError if has_children?
        super(obj)
      end

      def evaluate
        super
        first_child.evaluate.gsub(/with\(/, 'without(')
      end
    end
  end
end
