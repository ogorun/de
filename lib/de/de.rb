#
# De (Dynamic Expression) module provides means to build and evaluate
# dynamic expression of arbitrary complecity and operands/operators nature.
#
# Expression is considered as tree consisted of operands and operators.
# Operater must have child nodes. Operand is terminal node.
#
# Tree example:
#   (a + b) * c + d
#
#   - +
#   --- *
#   ----- +
#   ------- a
#   ------- b
#   --- d
#
#   Here "+" and "*" are operators,
#   "a", "b" and "d" are operands
#
# Expression tree structure is built with the help of <rubytree> gem
# (https://rubygems.org/gems/rubytree)
#
# In addition to basic classes of Expression, Operand and Operator
# module provides some extensions for different nature expressions:
#  - Boolean expressions
#  - Sunspot Solr search expressions
#


require 'tree'
require 'active_support/inflector'
require 'de/error'

module De

  #
  # Base class of De module
  # Represents tree of dynamic expression consisted of operators and operands
  # Provides means for expression tree building, validation and evaluation
  #
  class Expression < Tree::TreeNode

    #
    # Adds operator or operand as a child to Expression
    #
    # === Input
    #
    # obj<Operator|Operand>:: object to be added as child one
    #
    # === Output
    #
    # <Operator|Operand>:: child object
    #
    def <<(obj)
      raise Error::TypeError unless (obj.is_a?(Operator) or obj.is_a?(Operand))
      added = added_obj(obj)
      super(added)
    end

    #
    # Checks expression validity
    # Must be overriden by extending class
    #
    # === Input
    #
    # no input
    #
    # === Output
    #
    # true|false
    #
    def valid?
      raise Error::MethodShouldBeOverridenByExtendingClassError
    end

    #
    # Evaluates expression in case it is valid
    # otherwise raises exception
    # If expression valid returns true
    # Must be overriden in extending class to do some usefull evaluation
    #
    # === Input
    #
    #   params<Hash>:: optional paramters hash
    #
    # no input
    #
    # === Output
    #
    #  true
    #
    def evaluate(params = nil)
      raise Error::InvalidExpressionError unless valid?
      true
    end

    #
    # Override eql? and hash for consistent behaviour in hashes and arrays
    #

    def eql?(obj)
      self == obj
    end

    def hash
      @content.hash
    end
    
    def to_s
      str = @content.nil? ? '' : @content
      str +=  '(%s)' % children.map { |child| child.to_s }.join(', ') if children.length > 0

      str
    end

#    def to_hash
#      {
#        :name => @name,
#        :content => @content,
#        :class => self.class.name,
#        :children => children.map { |child| child.to_hash }
#      }
#    end

    class << self

#      def load(hash)
#        raise Error::InvalidExpressionError if (hash.keys - [:name, :content, :class, :children]).length > 0
#
#        klass = hash[:class].constantize
#        params = case klass.method(:new).arity
#        when -1,0 then []
#        when -2,1 then [hash[:name]]
#        else [hash[:name], hash[:content]]
#        end
#
#        obj = klass.send(:new, *params)
#        hash[:children].each { |child| obj << load(child) }
#      end
    end

    private

    #
    # Object to be added to current one
    #
    # Checks and prevents trial to add element with name already existent in objects children
    #
    # === Input
    #
    #  obj <Operator|Operand>:: potential child object
    #
    #  === Output
    #
    #  <Operator|Operand>
    #
    def added_obj(obj)
      dup_obj = obj
      counter = 0
      while @children_hash.key?(dup_obj.name) && counter < 5
        dup_obj.name = "#{dup_obj.name}_#{rand(1000000)}"
        counter += 1
      end

      dup_obj
    end
    
  end

  #
  # Class representing operator concept -
  # kind of expression that has children
  # 
  # Class can be considered abstract.
  # Its object creation is prevented by constructor.
  # Extending classes must be implemented
  # in order to work with this concept
  #
  class Operator < Expression

    #
    # Constructor. Prevents this class objects direct creation
    #
    # === Input
    #
    # name<String>
    # operands<Array>:: (optional) array of Operand objects.
    #    If given they are added as children to current operator
    #
    def initialize(name, content, operands = nil)
      raise Error::AbstractClassObjectCreationError if instance_of? Operator
      super(name, content)

      unless operands.nil?
        raise Error::TypeError unless operands.is_a?(Array)
        operands.each { |operand| self << operand }
      end
    end

    #
    # Checks expression validity
    # Operator is valid if it has children and every one from them is valid
    #
    # === Input
    #
    # no input
    #
    # === Output
    #
    # true|false
    #
    def valid?
      has_children? and children.inject(true) { |result, el| result and el.valid? }
    end

    #
    # Equal operator override
    # This basic implementation checks objects class, children number equality
    # and children equality. Operands order is important
    #
    def ==(obj)
      self.class.name == obj.class.name && children == obj.children
    end

    #
    # Define hash function to get equal results for operators from the same class and with the equal children
    #
    def hash
      [self.class.name, children.map { |el| el.hash }].hash
    end
  end

  #
  # Class representing operand concept -
  # kind of expression without children.
  #
  # Class can be considered abstract.
  # Its object creation is prevented by constructor.
  # Extending classes must be implemented
  # in order to work with this concept
  #
  class Operand < Expression
    #
    # Constructor. Prevents this class objects direct creation
    #
    # === Input
    #
    # name<String>
    # content<Object>:: arbitrary content. Its interpritation is done by extending classes
    #
    def initialize(name, content)
      raise Error::AbstractClassObjectCreationError if instance_of? Operand
      super(name, content)
    end

    #
    # Adding children to operand is prevented (raises exception)
    #
    def <<(obj)
      raise Error::TypeError
    end

    #
    # Evaluator must be overriden by extending classes (raises exception)
    #
    def evaluate
      raise Error::MethodShouldBeOverridenByExtendingClassError if instance_of? Operand
      super
    end
  end

end

module Tree
  class TreeNode
    attr_accessor :name
  end
end
