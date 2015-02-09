require './contracted'
#
# COPIED FROM contracted.rb:
#
#
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

class A < Contracted

    def my_to_s(count = 1)
        @thing * count
    end

    def initialize(str = "thing")
        super # super call is necessary for contracts to work!

        @thing = str

        addInvariant( Contract.new("member attribute must always be a string",
            Proc.new { @thing.is_a? String }
        ));

        addPrecondition( :my_to_s,
            Contract.new("if there is a parameter, parameter must be a positive integer",
            Proc.new do |*params|
                count = params[0]
                (count == nil) ||
                (count.is_a? Integer) && (count > 0)
            end
        ));

        addPostcondition( :my_to_s,
            Contract.new("result length must be count times existing string length",
            Proc.new do |returnVal, *params|
                count = params[0] || 1
                returnVal.length == @thing.length * count
            end
        ));

        addPostcondition( :my_to_s,
            Contract.new("result must be a string",
            Proc.new do |returnVal, *params|
                count = params[0] || 1
                returnVal.is_a? String
            end
        ));

    end

end

a = A.new("a")
a_with_contracts = ContractRunner.new(a)

puts "Bare object:"
puts a.my_to_s
puts ""

puts "Bare with contracts, valid my_to_s calls:"
puts a_with_contracts.my_to_s
puts a_with_contracts.my_to_s(5)
puts ""

puts "Bare with contracts, INVALID my_to_s calls:"
# will fail by exception raise
puts a_with_contracts.my_to_s(-3)
puts a_with_contracts.my_to_s("butt")
puts ""
