
# An invariant is a Proc that runs a test on object state.
# Returns true iff the test passes.
#
# EX: { @amounts.reduce(:+) <= @@MAX_SUM }
#
# A precondition is a Proc that runs a test on object state and/or
# method parameter.
# Returns true iff the test passes.
#
# EX: { |*parameters|  parameter[0].respond_to? :draw }
#     
# A postcondition is a Proc that runs a test on object state, return 
# value, and/or method parameters.
# Returns true iff the test passes.
#
# EX: { |returnVal, *parameters|  returnVal < @max }
#     
class Contracted

    private

    # Array of class invariants.
    @invariants

    # Hash from method names (Symbols) to method preconditions.
    @preconditions

    # Hash from method names (Symbols) to method postconditions.
    @postconditions

    # Hash from contracts (Procs) to warning labels (Strings)
    @contractLabels

    # Register an invariant for automatic verification
    # after every call.
    def addInvariant(label, invariant)
        getInvariants.push(invariant)
        @contractLabels[invariant] = label
    end

    # Register a precondition for automatic verification
    # before every call.
    def addPrecondition(method, label, precondition)
        getPreconditions(method).push(precondition)
        @contractLabels[precondition] = label
    end

    # Register a postcondition for automatic verification
    # after every call.
    def addPostcondition(method, label, postcondition)
        getPostconditions(method).push(postcondition)
        @contractLabels[postcondition] = label
    end

    public

    def initialize(*args)
        @invariants = Array.new
        @preconditions = Hash.new
        @postconditions = Hash.new
        @contractLabels = Hash.new
    end

    def getInvariants
        @invariants
    end

    def getPreconditions(method)
        @preconditions[method] = @preconditions[method] || Array.new
    end

    def getPostconditions(method)
        @postconditions[method] = @postconditions[method] || Array.new
    end

    def getContractLabel(contract)
        @contractLabels[contract]
    end

end

class ContractFailure < StandardError
    
    alias_method :set_backtrace_old, :set_backtrace

    def initialize(msg)
        super "\n\n" + msg
    end

    def set_backtrace(backtrace)
        set_backtrace_old(backtrace[5..backtrace.length]);
    end
end

class ContractRunner < BasicObject

    private

    @contractedObject

    public

    def initialize(contracted)
        @contractedObject = contracted

        # TODO verify that target responds to getPreconditions(:method)
        # containing Enumerable of Procs.  i.e. inherits Contracted
    end

    private

    def perr(*args)
        ::Kernel.STDERR.puts(*args)
    end

    def failContract(errMsg)
        ::Kernel.raise ::ContractFailure, errMsg
    end

    # Intercept method call to intended object.
    # Run preconditions, postconditions, invariants
    def method_missing(method, *args, &block)

        verifyPreconditions(method, *args)

        returnValue = @contractedObject.send(method, *args, &block)

        verifyPostconditions(method, returnValue, *args)

        verifyInvariants()
        
        returnValue
    end

    def verifyInvariants()
        @contractedObject.getInvariants().each do |invariant|
            if !invariant.call
                failContract "Invariant Failure: " +
                    @contractedObject.getContractLabel(invariant)
            end
        end
    end

    def verifyPreconditions(method, *args)
        # TODO preconditions on passed block...?
        @contractedObject.getPreconditions(method).each do |precondition|
            if !precondition.call(*args)
                failContract method.to_s + " Precondition Failure: " + 
                    @contractedObject.getContractLabel(precondition)
            end
        end
    end

    def verifyPostconditions(method, returnValue, *args)
        # TODO on passed block...? is that a thing?
        @contractedObject.getPostconditions(method).each do |postcondition|
            if !postcondition.call(returnValue, *args)
                failContract method.to_s + " Postcondition Failure: " + 
                    @contractedObject.getContractLabel(postcondition)
            end
        end
    end
end

