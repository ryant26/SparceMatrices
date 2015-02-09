require './contracted'

#
# internal syntax note: matrix coordinates are in row, column order.
# 	EX: [3, 1] is the only nonzero entry of the following 5x3 matrix
# 	    
# 	    | 0 0 0 |
# 	    | 0 0 0 |
# 	    | 0 0 0 |
# 	    | 0 7 0 |
# 	    | 0 0 0 |
#
class SparseMatrix < Contracted
	protected
	attr_reader :matrix, :rowCount, :colCount

	private
	# --------------------Factory Methods-------------------------
	def self.CreateMatrixFromPercentFull(rows, cols, percent)
		result = SparseMatrix.Zeros(rows, cols)
		nonZero = (rows * cols * percent).floor
		nonZero.times do 
			result.setElement([rand(1..rows), rand(1..cols)], rand(1..100))
		end
		result
	end

	def self.CreateTridiagonal(height, width)end

	def self.Zeros(height, width)
		SparseMatrix.new(height, width)
	end

	def self.Identity(size)
		out = SparseMatrix.new(size, size)
		(1..size).each { |x| out.setElement([x, x], 1)}
		out
	end

	def self.FromHash(input, rows, columns)
		m = SparseMatrix.Zeros(rows, columns)
		m.matrix = input
	end

	def self.Build(height, width)
		result = SparseMatrix.new(height, width)
		height.times do |i|
			width.times do |j|
				result.setElement([i,j], (yield i, j))
			end
		end
		result
	end
	
	public
	def initialize(rows, columns)
		@matrix = Hash.new(0)
		@rowCount = rows
		@colCount = columns

                super #<-- superconstructor necessary for contracts
                addInvariants
                addPreconditions
                addPostconditions
	end



	# ----------------------------Arithmatic-------------------------------

	# pre matrix should be same size
	# post matrix should be same size
	def add(matrix)
		result = clone
		result.sparseMerge!(matrix) { |key, oldval, newval| oldval + newval }
		return result
	end
	
	# pre matrix should be same size
	# post matrix should be same size
	def subtract(matrix)
		result = clone
		result.sparseMerge!(matrix) { |key, oldval, newval| oldval - newval }
		return result
	end

	# pre matrix should be correct dimensions
	# post matrix should be correct dimensions
	def multiply(matrix)
		#DOK was a bad data choice for ordered iteration, we could considder a to_a function thtat uses another format possibly
		result = SparseMatrix.Zeros(@rowCount, @colCount)
		if matrix.respond_to? :getElement
			(1..@rowCount).each do |i|
				(1..matrix.colCount).each do |k|
					sum = 0
					(1..@colCount).each do |j|
						if (@matrix.key?([i,j]))
							sum += getElement([i,j]) * matrix.getElement([j, k])
						end
					end
					result.setElement([i, k], sum)
				end
			end
		elsif matrix.is_a? Numeric
			result.matrix.each { |key, value| result.setElement(key, matrix * value)}
		end
		return result
	end

	# ---------------------------Properties---------------------------------


	# ---------------------Ruby Overrides (or similar)----------------------

	# does not scale to large sparse matrices - all values printed
	def to_s
		#This looks bad when there are long (many digit) non-zero elements
		(1..@rowCount).each do |i|
			print "| "
			(1..@colCount).each do |j|
				print "#{getElement([i,j])} "
			end
			puts "|"
		end
	end

	# scales to large matrices without creating huge strings - zeros omitted
	# prints coordinate value pairs sorted by coordinate, i,j : <val>
	def to_s_minimal
		matrix.each {|key, val| puts "#{key} #{val}"}
	end

	
	# ----------------------------Infastructure---------------------------

	def setElement(key, value)
		if value == 0
			@matrix.delete(key)
		else
			@matrix[key] = value
		end
	end

	def getElement(key)
		@matrix[key]
	end


	# precond
	# 	dim must be an integer > 1 or a 2-member array of integer > 1
	# postcond
	# 	will set the instance members rowCount and colCount
	def setDimensions(dim)
		# inspect dimension
		if dim.is_a? Array
			@rowCount, @colCount = dim[0], dim[1]
		else
			@rowCount, @colCount = dim, dim
		end
	end

	# Identical to hash.merge!, but clears zero values from map
	def sparseMerge!(matrix)
		matrix.matrix.each do |key, val|
			setElement(key, (yield key, @matrix[key], val))
		end
	end

	def clone()
		result = SparseMatrix.Zeros(@rowCount, @colCount)
		@matrix.each { |key, val| result.setElement(key, val)}
		return result
	end

	#matrix is non-singular (invertable)
	def inverse()
		(1/determinant) * clone.adjoint
	end

	#precondit must be square
	def adjoint()
		cofactorMatrix.transpose
	end

	def transpose()
		@matrix.each {|key, val| key[0], key[1] = key[1], key[0]}.rehash
	end

	#precondit must be squaare
	def cofactorMatrix()
		minorMatrix.matrix.each {|key ,val| minorMatrix.setElement(key, ((-1)**(key[0] + key[1])) * val)}
	end

	#precondit must be square
	def minorMatrix()
		out = SparseMatrix.Zeros
		(1..@rowCount).each { |i| (1..@colCount).each { |j| out.setElement([i, j], minor(i,j).determinant) } }
		out
	end

	#precondit must be square
	def minor(rd, cd)
		#returns the sub matrix for a row and column deletion
		m = @matrix.reject {|key, val| key[0] == rd || key[1] == cd}.map do |key ,val|
			key[0] -= 1 if key[0] > rd
			key[1] -= 1 if key[1] > cd
			[key, val]
		end
		SparseMatrix.FromHash(Hash[m])
	end


	#precondit must be square
	def determinant()
		#LUPR is the Lower, Upper, and Permutation Matrices, R is the number of row exchanges in the decomposition
		lupr = decompose
		a = (-1)**lupr[3]
		b = determinantTriangular(lupr[0])
		c = determinantTriangular(lupr[1])
		a*b*c
	end

	#precondit matrix must be triangular
	def determinantTriangular(matrix)
		#DET of any triangular matrix is the product of it's diagonal elements
		#Refactoring opertunity, use inject
		product = 1
		(1..matrix.colCount).each { |i| product *= matrix.getElement([i,i])}
		product
	end

	#precondit must be square
	def decompose()
		pivot =  getPivot
		rowEchanges = pivot[1]
		pivot = pivot[0]
		temp = pivot * self
		u = SparseMatrix.Zeros(@rowCount, @colCount)
		l = SparseMatrix.Identity(@colCount)
		(1..@rowCount).each do |i|
			(1..@colCount).each do |j|
				if j >= i 
					#working on upper half
					u.setElement([i,j], ( temp.getElement([i,j]) - (1..i).inject(0.0) {|sum, k| sum + u.getElement([k, j]) * l.getElement([i, k])} ) )
				else
					#working on lower half
					l.setElement([i,j], ( temp.getElement([i,j]) - (1..j).inject(0.0) {|sum, k| sum + u.getElement([k, j]) * l.getElement([i, k])} ) / u.getElement([j, j]) )
				end
			end
		end
		[l,u,pivot, rowEchanges]
	end

	#precondit must be square
	def getPivot() 
		id = SparseMatrix.Identity(@rowCount)
		rowEchanges = 0;
		(1..@colCount).each do |j|
			max = getElement([j, j])
			row = j
			(j..@rowCount).each do |i|
				if getElement([i,j]) > max
					max = getElement([i,j])
					row = i
				end
			end
			id.swapRow([j,j], [row, row])
			rowEchanges += 1 if j != row
		end
		[id, rowEchanges]
	end

	def swapRow(key1, key2)
		val1 = getElement(key1)
		val2 = getElement(key2)
		@matrix.delete(key1)
		@matrix.delete(key2)

		setElement([key2[0], key1[1]], val1)
		setElement([key1[0], key2[1]], val2)
	end

	alias * multiply
	alias + add
	alias - subtract

	# --------------------------- Invariants --------------------------

        def addInvariants
            addInvariant(Contract.new(
                "matrix must contain fewer elements than M * N",
                Proc.new { @matrix.length <= @rowCount * @colCount }
            ))
        end

	# -------------------------- Preconditions -------------------------

        def addPreconditions

            inputIsMatrix = Contract.new(
                "input must be a sparse matrix",
                Proc.new do |*params|
                    matrix = params[0]
                    (matrix.respond_to? :colCount) &&
                    (matrix.respond_to? :rowCount)
                end
            )

            inputSameSize = Contract.new(
                "input matrix must be identical size",
                Proc.new do |*params|
                    matrix = params[0]
                    (matrix.colCount == @colCount) &&
                    (matrix.rowCount == @rowCount)
                end
            )

            numericOrMatrix = Contract.new(
                "input must be numerical value or a matrix",
                Proc.new do |*params|
                    (params[0].is_a? Numeric) || 
                    (params[0].respond_to? :getElement)
                end
            )
            
            matrixCompatibleMultiply = Contract.new(
                "input matrix must be of compatible size",
                Proc.new do |*params|
                    matr = params[0]
                    if (matr.respond_to? :rowCount) && 
                       (matr.respond_to? :colCount)
                        @rowCount = matr.colCount
                        @colCount = matr.rowCount
                    else
                        true
                    end
                end
            )

            addPrecondition(:add, inputIsMatrix)
            addPrecondition(:add, inputSameSize)

            addPrecondition(:subtract, inputSameSize)
            addPrecondition(:subtract, inputIsMatrix)

            addPrecondition(:multiply, numericOrMatrix)
            addPrecondition(:multiply, matrixCompatibleMultiply)

        end

	# -------------------------- Postconditions -------------------------

        def addPostconditions
            
            resultSameSize = Contract.new(
                "returned matrix must be identical size",
                Proc.new do |returnMatrix|
                    returnMatrix.colCount == @colCount &&
                    returnMatrix.rowCount == @rowCount
                end
            )

            addPostcondition(:add, resultSameSize);
            addPostcondition(:subtract, resultSameSize);

        end

end


myMAt = ContractRunner.new(SparseMatrix.CreateMatrixFromPercentFull(5, 5, 0.2))
myMAt2 = ContractRunner.new(SparseMatrix.CreateMatrixFromPercentFull(5, 5, 0.25))
puts "------------ Matrix 1---------------"
puts myMAt
puts "-------------Matrix 2---------------"
puts myMAt2
puts "-------------1  +   2---------------"
puts myMAt2.add(myMAt)
puts "-------------2  -   1---------------"
puts myMAt2.subtract(myMAt)

puts "-------------Matrix 3---------------"
m = ContractRunner.new(SparseMatrix.CreateMatrixFromPercentFull(5, 5, 0.75))
puts m
puts "-------------  * -3  ---------------"
puts m.multiply(-3)
puts "=====================LUP Decomposition==============="
puts ContractRunner.new(SparseMatrix.Identity(10))

m = ContractRunner.new(SparseMatrix.Zeros(3,3))
m.setElement([1,1], 1)
m.setElement([1,2], 3)
m.setElement([1,3], 5)
m.setElement([2,1], 2)
m.setElement([2,2], 4)
m.setElement([2,3], 7)
m.setElement([3,1], 1)
m.setElement([3,2], 1)
m.setElement([3,3], 0)
puts "---------------------- orig------------------------"
puts m
a = 2
puts "---------------------- pivot------------------------"
out = m.decompose
puts "---------------------- L ---------------------------"
puts out[0]
puts "---------------------- U ---------------------------"
puts out[1]
puts "---------------------- P ---------------------------"
puts out[2]
puts "----------------------# Row swaps-------------------"
puts out[3]
puts "-----------------------Determinant Test------------------"
m = SparseMatrix.Zeros(3,3)
m.setElement([1,1], 1)
m.setElement([1,2], 2)
m.setElement([1,3], 3)
m.setElement([2,1], 3)
m.setElement([2,2], 2)
m.setElement([2,3], 1)
m.setElement([3,1], 2)
m.setElement([3,2], 1)
m.setElement([3,3], 3)
puts m
puts "Determinant is #{m.determinant} == -12?"
