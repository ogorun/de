module De
  module Error
    exceptions = %w[TypeError ArgumentNumerError InvalidExpressionError AbstractClassObjectCreationError MethodShouldBeOverridenByExtendingClassError]
    exceptions.each { |e| const_set(e, Class.new(StandardError)) }  
  end
end
