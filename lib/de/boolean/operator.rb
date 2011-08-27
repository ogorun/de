#
# De::Boolean::Operator class
#
# De::Boolean module provides means for dynamic logical expression building/validation/evaluation
# It is built as extension of De module
#
# Boolean expression example:
#
# true AND (false OR true)
#
#

require 'de/symmetric_operator'

module De
  module Boolean

    # Marker module included to all module classes
    # to be able to check that class is inside module
    module Bn; end

    #
    # Class representing Boolean operator
    # Base abstract class for concrete operators AND, OR, NOT
    #
    class BooleanOperator < Operator
      include Bn
      include De::SymmetricOperator

      #
      # Constructor. Prevents direct BooleanOperator class objects creation
      #
      # === Input
      #
      # name<String>
      # operands<Array>:: (optional) array of Operand objects.
      #    If given they are added as children to current operator
      #
      def initialize(name, operands = nil)
        raise Error::AbstractClassObjectCreationError if instance_of? BooleanOperator
        super(name, operands)
      end

      #
      # Adds boolean operator or operand as a child to boolean operator
      #
      def <<(obj)
        raise Error::TypeError unless obj.is_a?(De::Boolean::Bn)
        super(obj)
      end
      
    end

    #
    # Class representing boolean AND operator
    #
    class And < BooleanOperator

      #
      # Creates And object.
      # Name includes word 'AND' with random number to avoid TreeNode problem
      # when trying to add children with the same name to a node
      #
      # === Input
      #
      # operands<Array>:: (optional) array of Operand objects.
      #    If given they are added as children to current operator
      #
      def initialize(operands = nil)
        super("AND-#{rand(1000)}", operands)
      end

      def evaluate
        super
        children.inject(true) {|result, el| result && el.evaluate}
      end
    end

    #
    # Class representing boolean OR operator
    #
    class Or < BooleanOperator

      #
      # Creates Or object.
      # Name includes word 'AND' with random number to avoid TreeNode problem
      # when trying to add children with the same name to a node
      #
      # === Input
      #
      # operands<Array>:: (optional) array of Operand objects.
      #    If given they are added as children to current operator
      # 
      def initialize(operands = nil)
        super("OR-#{rand(1000)}", operands)
      end

      def evaluate
        super
        children.inject(false) {|result, el| result || el.evaluate}
      end
    end

    #
    # Class representing boolean NOT operator
    #
    class Not < BooleanOperator

      #
      # Creates Not object.
      # Name includes word 'AND' with random number to avoid TreeNode problem
      # when trying to add children with the same name to a node
      #
      # === Input
      #
      # operand<De::Boolean::Operand>:: (optional) Operand object.
      #    If given it is added as child to current operator
      #
      def initialize(operand = nil)
        super("NOT-#{rand(1000)}", operand ? [operand] : nil)
      end

      def <<(obj)
        raise Error::ArgumentNumerError if has_children?
        super(obj)
      end

      def evaluate
        super
        !first_child.evaluate
      end
    end
  end
end
