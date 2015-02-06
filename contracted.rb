class Contracted
    
    # Array of class invariants.
    # An invariant is a Proc that runs a test on object state and returns
    # true iff the test passes.
    @invariants = Array.new

    # Hash from method names (Symbols) to method preconditions.
    # A precondition is a Proc that runs a test on object state and/or
    # method parameter, returning true iff the test passes.
    #
    # EX: { |*parameters|  parameter[0].respond_to? :draw }
    #     
    @preconditions = Hash.new

    # Hash from method names (Symbols) to method postconditions.
    # A postcondition is a Proc that runs a test on object state and/or
    # method return value, returning true iff the test passes.
    #
    # EX: { |returnVal|  returnVal < @max }
    #     
    @postconditions = Hash.new



    def getPreconditions(method)
        @preconditions[method] = @preconditions[method] || Array.new
    end

    # Register one or more preconditions for automatic verification
    # on every call.
    def registerPrecondition(method, *precondition)
        getPreconditions(method).push(precondition);

        # TODO redefine method, alias old & verify
        self.send(:alias_method, "#{method}_original", method)
    end

    # Note:  right now this doesn't return *which* precondition failed.
    def verifyPreconditions(method, *parameters)
        getPreconditions(method).each do |precondition|
            precondition.call(parameters)
        
        end
    end
end
