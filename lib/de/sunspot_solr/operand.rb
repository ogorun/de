#
# De::SunspotSolr operand classes.
# This file defines:
#  - basic De::SunspotSolr::SunspotOperand class
#  - De::SunspotSolr::IntervalSunspotOperand extending SunspotOperand for case of time intervals
#  - A number of classes extending mentioned below and giving convenient interface for concrete sunspot query operations:
#    - EqualTo, Without, GreaterThan, LessThan, Between, AnyOf, GreaterThanOrEqual, LessThanOrEqual
#    - IntervalFromNowEqualTo, IntervalFromNowWithout, IntervalFromNowGreaterThan, IntervalFromNowLessThan, IntervalFromNowBetween,
#      IntervalFromNowAnyOf, IntervalFromNowGreaterThanOrEqual, IntervalFromNowLessThanOrEqual
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
#   with(:update_time).greater_then('2011-03-15 15:00:00')
# end
#

#require 'active_support/inflector'
require 'active_support/all'

module De
  module SunspotSolr

    # Marker module included to all module classes
    # to be able to check that class is inside module
    module SP; end

    #
    # Basic class representing sunspot search expression operand
    # 
    # Operand representation in Sunspot query examples:
    # - with(:client_id).equal_to(43)
    # - with(:update_time).greater_then('2011-03-15 15:00:00')
    # 
    #
    class SunspotOperand < Operand
      include De::SunspotSolr::SP

      attr_reader :value, :operand

      #
      # Constructor for SunspotOperand
      # Stores name and property as TreeNode's @name and @content correspondingly
      #
      # === Input
      #
      # name<String|Symbol>:: arbitrary object name
      # property<String|Symbol>:: property examined by sunspot query
      #     (for example, :client_id in condition with(:client_id).equal_to(43)
      #     Stored as TreeNode's @content field
      # operand<Symbol>:: operand type
      #     Examples: :equal_to, :without, :greater_than...
      # value<Object>:: value to compare
      #     Example: 43 in condition with(:client_id).equal_to(43)
      #
      def initialize(name, property, operand, value)
        super(name.to_s, property.to_s)
        @value = value
        @operand = operand
      end

      #
      # Validation
      #
      # Operand is valid in case
      #  - its operand is included to valid_operands list
      #  - it is added to De::SunspotSolr::Search object and property is registered in this root object
      #    Last one is needed to choose appropriate condition representation according to property type and static/dynamic nature
      #
      def valid?
        return false unless self.class.valid_operands.include?(@operand)
        return false unless root.is_a?(Search)
        return false unless root.options[:properties].key?(@content.to_sym)
        true
      end

      #
      # Evaluation
      #
      #  Result depends on property type and static/dynamic nature
      #
      # === Output
      #
      #  <String> - string representation of sunspot condition
      #
      def evaluate
        super
        if root.options[:properties][@content.to_sym][:dynamic]
          "dynamic(:#{root.options[:dynamics][root.options[:properties][@content.to_sym][:type]]}) do
             #{simple_evaluate}
           end"
        else
          simple_evaluate
        end
      end

      #
      # Equal operand override
      # Checks objects class and coincidence of +operand+, +value+ and +property+ (stored in +content+ filed)
      #
      # === Input
      #
      # obj<SunspotOperator>:: object to compare with
      #
      def ==(obj)
        obj.is_a?(SunspotOperand) && obj.operand == @operand && obj.content == @content && obj.value == @value
      end

      #
      # Define hash function to give the same result for equal @operand, @content and @value
      # (@name is not important for equal operands)
      #
      def hash
        [@operand, @content, @value].hash
      end

      class << self

        #
        # Supported operands list
        #
        # === Output
        #
        #  <Array> of symbols
        #
        def valid_operands
          [:equal_to, :greater_than, :less_than, :between, :any_of]
        end
      end

      protected

      def simple_evaluate
        "with(:#{@content}).#{@operand}(#{value_to_compare})"
      end

      def value_to_compare
        if @value.is_a?(Array)
          output = "[#{@value.map {|element| atomic_value(element) }.join(',')}]"
        elsif @value.is_a?(Range)
          output = @value.exclude_end? ? atomic_value(@value.first)...atomic_value(@value.last) : atomic_value(@value.first)..atomic_value(@value.last)
        else
          output = atomic_value(@value)
        end

        output
      end

      def atomic_value(val)
        case root.options[:properties][@content.to_sym][:type]
        when :text, :string
          "'#{val.escape_apos}'"
        when :time
          "'#{val.to_s(:db)}'"
        when :float
          val.to_f
        else
          val
        end
      end
    end

    #
    # Sunspot interval operand class
    #
    # It expends SunspotOperand class for properties of type :time
    # and evaluates their values compared to given by interval from now.
    # Interval is considered in days
    #
    # For example
    #
    #   IntervalSunspotOperand.new('op1', :start_date, :less_then, 3)
    #
    #   gives condition
    #
    #   with(:start_date).less_than(Time.now + 3.days)
    #
    class IntervalSunspotOperand < SunspotOperand

      def valid?
        super && root.options[:properties][@content.to_sym] && root.options[:properties][@content.to_sym][:type] == :time
      end

      protected

      def value_to_compare
        now = Time.now
        if @value.is_a?(Array)
          shifted_value = "[#{@value.map {|element| atomic_value(now  + element.days)  }.join(',')}]"
        elsif @value.is_a?(Range)
          shifted_value = @value.exclude_end? ? 
                "#{atomic_value(now + @value.first.days)}...#{atomic_value( now + @value.last.days)}" :
                "#{atomic_value(now + @value.first.days)}..#{atomic_value( now + @value.last.days)}"
        else
          shifted_value = atomic_value(now + @value.days)
        end
        
        shifted_value
      end
    end

    available_operands = SunspotOperand.valid_operands | [:greater_than_or_equal, :less_than_or_equal, :without]
    available_operands.each do |operand|
      module_eval "
        class #{operand.to_s.camelize} < SunspotOperand
          def initialize(property, value)
            super(\"\#\{property\}-\#\{rand(1000)\}\", property, :#{operand}, value)
          end

          def self.valid_operands
            [:#{operand}]
          end
        end

        class IntervalFromNow#{operand.to_s.camelize} < IntervalSunspotOperand
          def initialize(property, value)
            super(\"\#\{property\}-\#\{rand(1000)\}\", property, :#{operand}, value)
          end

          def self.valid_operands
            [:#{operand}]
          end
        end
      "
    end

    [:greater_than_or_equal, :less_than_or_equal].each do |operand|
      module_eval %{
        class #{operand.to_s.camelize} < SunspotOperand

          def simple_evaluate
            "any_of do
               with(:\#\{@content\}).#{operand.to_s.gsub(/_or_equal/, '')}(\#\{value_to_compare\})
               with(:\#\{@content\}, \#\{value_to_compare\})
             end"
          end
        end

        class IntervalFromNow#{operand.to_s.camelize} < IntervalSunspotOperand

          def simple_evaluate
            "any_of do
               with(:\#\{@content\}).#{operand.to_s.gsub(/_or_equal/, '')}(\#\{value_to_compare\})
               with(:\#\{@content\}, \#\{value_to_compare\})
             end"
          end
        end
      }
    end

    class Without < SunspotOperand

      def simple_evaluate
        "without(:#{@content}, #{value_to_compare})"
      end
    end

    class IntervalFromNowWithout < IntervalSunspotOperand
      
      def simple_evaluate
        "without(:#{@content}, #{value_to_compare})"
      end
    end
  end
end
