#
# De::Boolean::Operand class
#
# De::Boolean module provides means for dynamic logical expression building/validation/evaluation
# It is built as extension of De module
#
# Boolean expression example:
#
# true AND (false OR true)
#

module De
  module Boolean

    # Marker module included to all module classes
    # to be able to check that class is inside module
    module Bn; end
    
    #
    # Class representing Boolean operand
    #
    class Operand < De::Operand
      include Bn

      #
      # Checks content is boolean value
      #
      # === Output
      #
      # true|false
      #
      def valid?
        content.is_a?(TrueClass) || content.is_a?(FalseClass)
      end

      #
      # Returns value stored in content field if it is valid
      # or raises exception
      #
      def evaluate
        super
        content
      end
    end
  end
end