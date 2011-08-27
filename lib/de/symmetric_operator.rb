#
# Symmetric operator module defines properties for operator with unimportant order of children (operands)
# 

require 'set'

module De
  module SymmetricOperator
    
    #
    # Equal operator override
    # Checks objects class and children equality. Operands order is NOT important
    #
    # === Input
    #
    # obj<Expression>:: object to compare with
    #
    def ==(obj)
      self.class.name == obj.class.name && ((children | obj.children) - (children & obj.children)).length == 0
    end

    #
    # Define hash function to get equal results for operators from the same class and with the equal children.
    # Children order is not important
    #
    def hash
      [self.class.name, Set.new(children.map { |el| el.hash})].hash
    end
      
  end
end
