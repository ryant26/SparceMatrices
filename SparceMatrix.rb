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
	public
	attr_reader :matrix, :rowCount, :colCount

	private
	
	def initialize(rows, columns)
		@matrix = Hash.new(0)
		@rowCount = rows
		@colCount = columns

        super #<-- superconstructor necessary for contracts
        addInvariants
        addPreconditions
        addPostconditions
	end

	public
	# --------------------Factory Methods-------------------------
	def self.FromPercentFull(rows, cols, percent)
		SparseMatrixFactory do
			result = SparseMatrix.Zeros(rows, cols)
			nonZero = (rows * cols * percent).floor
			nonZero.times do 
				result.setElement([rand(1..rows), rand(1..cols)], rand(1..100))
			end
			result
		end
	end

	def self.Zeros(height, width)
		SparseMatrixFactory { SparseMatrix.new(height, width) }
	end

	def self.Identity(size)
		SparseMatrixFactory do
			out = SparseMatrix.new(size, size)
			(1..size).each { |x| out.setElement([x, x], 1)}
			out
		end
	end

	def self.FromHash(input, rows, columns)
		SparseMatrixFactory do	
			m = SparseMatrix.Zeros(rows, columns)
			input.default = 0
			m.setData(input)
			m
		end
	end

	def self.Build(height, width)
		SparseMatrixFactory do 
			result = SparseMatrix.new(height, width)
			(1..height).each do |i|
				(1..width).each do |j|
					result.setElement([i,j], (yield i, j))
				end
			end
			result
		end
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
	def multiply(matrix, mutate=false)
		#DOK was a bad data choice for ordered iteration, we could considder a to_a function thtat uses another format possibly
		if matrix.respond_to? :getElement
			mutate ? result = self : result = SparseMatrix.Zeros(@rowCount, matrix.colCount)
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
			mutate ? result = self : result = clone
			result.matrix.each { |key, value| result.setElement(key, matrix * value)}
		end
		return result
	end

	def multiply!(input)
		multiply(input, true)
	end
	# ----------------------------Transformations---------------------------

	def inverse()
		cofactorMatrix * (1/determinant)
	end

	def inverse!()
		setData(inverse.matrix)
	end

	def transpose()
                largestDim = [@rowCount, @colCount].max
		m = clone.resize!(largestDim, largestDim)
		m.matrix.each {|key, val| key[0], key[1] = key[1], key[0]}.rehash
		m.resize!(@colCount, @rowCount)
	end

	def transpose!()
                largestDim = [@rowCount, @colCount].max
                resize!(largestDim, largestDim)
		@matrix.each {|key, val| key[0], key[1] = key[1], key[0]}.rehash

                resize!(@colCount, @rowCount)
		self
	end

	def resize(rows, columns)
    	changeMatrixSize(clone, rows, columns)
    end

 	def resize!(rows, columns)
    	changeMatrixSize(self, rows, columns)
	end

	# ---------------------------Properties---------------------------------
        
        def isSquare
            @rowCount == @colCount
        end

        def isDiagonal
            offDiagonal = @matrix.select { |coord| coord[0] != coord[1] }
            isSquare && offDiagonal.length == 0
        end

        def isIdentity
            notOnes = @matrix.select { |coord, val| val != 1 }
            isDiagonal && notOnes.length == 0
        end

        def isInvertable()
        	# We can test for things like isSquare, but ultimately we need to find the determinant.
        	# That takes almost as long as just doing the inversion. Something we couldtalk about in the report
        	# is that we could compute the determinant in here and cache it for when someone decides to acually 
        	# perform the inversion..
        	return false if isZero
        	return false unless isSquare
        	d = determinant
        	return false unless d != 0
        	return false if d.nan?  
        	return true
        end

        def isSingular()
        	!(isInvertable)
        end

        def isZero()
        	@matrix.size == 0
        end

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

	def setData(value)
		@matrix = value
	end

	def clone()
		result = SparseMatrix.Zeros(@rowCount, @colCount)
		@matrix.each { |key, val| result.setElement(key.dup, val)}
		return result
	end

	#precondit must be square
	def adjoint()
		m = cofactorMatrix
		m.transpose!
	end

	#precondit must be squaare
	def cofactorMatrix()
		m = minorMatrix
		m.matrix.each {|key ,val| m.setElement(key, ((-1)**(key[0] + key[1])) * val)}
		m
	end

	#precondit must be square
	def minorMatrix()
		out = SparseMatrix.Zeros(@rowCount, @colCount)
		(1..@rowCount).each { |i| (1..@colCount).each { |j| out.setElement([i, j], minor(i,j).determinant) } }
		out
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

	protected
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

	def changeMatrixSize (matrix, rows, columns)
		matrix.setDimensions([rows,columns])
		matrix.matrix.reject! {|key ,val| key[0] > rows || key[1] > columns}
		matrix
	end

	# Identical to Hash.merge!, but clears zero values from map
	def sparseMerge!(matrix)
		matrix.matrix.each do |key, val|
			setElement(key, (yield key, @matrix[key], val))
		end
	end

	#precondit must be square
	def minor(rd, cd)
		#returns the sub matrix for a row and column deletion
		m = clone.matrix.reject {|key, val| key[0] == rd || key[1] == cd}.map do |key ,val|
			key[0] -= 1 if key[0] > rd
			key[1] -= 1 if key[1] > cd
			[key, val]
		end
		SparseMatrix.FromHash(Hash[m], @rowCount-1, @colCount-1)
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
			id.swapRow!([j,j], [row, row])
			rowEchanges += 1 if j != row
		end
		[id, rowEchanges]
	end

	def swapRow!(key1, key2)
		val1 = getElement(key1)
		val2 = getElement(key2)
		@matrix.delete(key1)
		@matrix.delete(key2)

		setElement([key2[0], key1[1]], val1)
		setElement([key1[0], key2[1]], val2)
	end

	def self.SparseMatrixFactory()
		ContractRunner.new(yield)
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

            ## getters and setters

            elementCoordArray = Contract.new(
                "element coordinates must be 2 element array",
                Proc.new do |key|
                    key.is_a?(Array) && key.length == 2
                end
            )

            elementCoordInt = Contract.new(
                "element coordinates must be integers within matrix bounds",
                Proc.new do |key|
                    pass = true
                    pass &= key[0].is_a?(Integer) && key[0] > 0 && key[0] <=  @rowCount
                    pass &= key[1].is_a?(Integer) && key[1] > 0 && key[1] <= @colCount

                    puts key if !pass

                    pass
                end
            )

            valueNumerical = Contract.new(
                "elements may only be numerical values",
                Proc.new { |key, value| value.is_a? Numeric }
            )
            
            dimensionsPositiveNumerical = Contract.new(
                "dimensions must be positive and integral (single int or 2 element array)",
                Proc.new do |dim|
                    pass = true
                    if dim.is_a? Array
                        pass &= dim.length == 2
                        pass &= dim[0].is_a?(Integer) && dim[0] > 0
                        pass &= dim[1].is_a?(Integer)  && dim[1] > 0
                    else
                        pass &= dim.is_a?(Integer)  && dim > 0
                    end
                    pass
                end
            )

            addPrecondition(:getElement, elementCoordArray)
            addPrecondition(:getElement, elementCoordInt)

            addPrecondition(:setElement, elementCoordArray)
            addPrecondition(:setElement, elementCoordInt)
            addPrecondition(:setElement, valueNumerical)

            addPrecondition(:setDimensions, dimensionsPositiveNumerical)

            ## operations

            inputIsMatrix = Contract.new(
                "input must be a sparse matrix",
                Proc.new do |matrix|
                    (matrix.respond_to? :colCount) &&
                    (matrix.respond_to? :rowCount)
                end
            )

            inputSameSize = Contract.new(
                "input matrix must be identical size",
                Proc.new do |matrix|
                    (matrix.colCount == @colCount) &&
                    (matrix.rowCount == @rowCount)
                end
            )

            numericOrMatrix = Contract.new(
                "input must be numerical value or a matrix",
                Proc.new do |param|
                    (param.is_a? Numeric) || 
                    (param.respond_to? :getElement)
                end
            )
            
            matrixCompatibleMultiply = Contract.new(
                "input matrix must be of compatible size",
                Proc.new do |matr|
                    if (matr.respond_to? :rowCount) && 
                       (matr.respond_to? :colCount)
                        @rowCount == matr.colCount &&
                        @colCount == matr.rowCount
                    else
                        true # contract does not apply for non matrix input
                    end
                end
            )

            matrixSquare = Contract.new(
                "input matrix must be square",
                Proc.new { isSquare }
            )

            nonzeroDeterminant = Contract.new(
                "input matrix must have nonzero determinant, and it must exist",
                Proc.new do 
                	d = determinant
                	(d != 0) && (!d.nan?)
                end
            )

            addPrecondition(:add, inputIsMatrix)
            addPrecondition(:add, inputSameSize)
            addPrecondition(:+, inputIsMatrix)
            addPrecondition(:+, inputSameSize)

            addPrecondition(:subtract, inputSameSize)
            addPrecondition(:subtract, inputIsMatrix)
            addPrecondition(:-, inputSameSize)
            addPrecondition(:-, inputIsMatrix)

            addPrecondition(:multiply, numericOrMatrix)
            addPrecondition(:multiply, matrixCompatibleMultiply)
			addPrecondition(:*, numericOrMatrix)
            addPrecondition(:*, matrixCompatibleMultiply)

            addPrecondition(:determinant, matrixSquare)

            addPrecondition(:inverse, matrixSquare)
            addPrecondition(:inverse, nonzeroDeterminant)


        end

	# -------------------------- Postconditions -------------------------

        def addPostconditions
            
            ## operations
            
            resultSameSize = Contract.new(
                "returned matrix must be identical size",
                Proc.new do |returnMatrix|
                    returnMatrix.colCount == @colCount &&
                    returnMatrix.rowCount == @rowCount
                end
            )

            resultScalarMultiplySize = Contract.new(
                "matrix scalar product must be identical size",
                Proc.new do |returnMatrix, *params|
                    scalar = params[0]
                    if scalar.is_a? Numeric
                        (returnMatrix.colCount == @colCount) &&
                        (returnMatrix.rowCount == @rowCount)
                    else
                        true
                    end
                end
            )

            resultMultiplySize = Contract.new(
                "matrix product must have: " + 
                "colCount == receiver colCount, rowCount == input colCount",
                Proc.new do |returnMatrix, matr|
                    if (matr.respond_to? :rowCount) && 
                       (matr.respond_to? :colCount)
                        (returnMatrix.colCount == @colCount) &&
                        (returnMatrix.rowCount == matr.colCount)
                    else
                        true
                    end
                end
            )

            equalTransposeDeterminant = Contract.new(
                "result determinant must be identical to transpose determinant",
                Proc.new do |result|
                	if (!result.nan?)
                    	10E-10 >= result - transpose.determinant
                	else
                		true
                	end
                end
            )

            transposeSizeSwap = Contract.new(
                "transpose must swap row and column counts",
                Proc.new do
                    t = transpose
                    t.rowCount == @colCount &&
                    t.colCount == @rowCount
                end
            )

            resultSameDeterminant = Contract.new(
                "result must have the same determinant",
                Proc.new do |result|
                    1E-10 >= result.determinant - determinant
                end
            )

            resultSameInvertibility = Contract.new(
                "result must be same invertibility",
                Proc.new do |result|
                    result.isInvertable == isInvertible
                end
            )

            dimensionsChanged = Contract.new(
                "matrix must have changed dimensions",
                Proc.new do |changed, rows, columns|
                    changed.rowCount == rows
                    changed.colCount == columns
                end
            )

            addPostcondition(:add, resultSameSize)

            addPostcondition(:subtract, resultSameSize)

            addPostcondition(:multiply, resultScalarMultiplySize)
            addPostcondition(:multiply, resultMultiplySize)
            addPostcondition(:*, resultScalarMultiplySize)
            addPostcondition(:*, resultMultiplySize)

            addPostcondition(:inverse, resultSameSize)

            #addPostcondition(:determinant, equalTransposeDeterminant)

            addPostcondition(:transpose, transposeSizeSwap)
            #addPostcondition(:transpose, resultSameDeterminant)
            #addPostcondition(:transpose, resultSameInvertibility)

            addPostcondition(:resize, dimensionsChanged)
            addPostcondition(:resize!, dimensionsChanged)

            ## properties
            
            identityDeterminant = Contract.new(
                "identity matrix must have determinant 1",
                Proc.new do |result|
                    if result
                        determinant == 1 
                    else
                        true # return true if result is false
                    end
                end
            )

            invertibleDeterminant = Contract.new(
                "invertible matrix must have inverse determinant inverse",
                Proc.new do |result|
                    if result
                        1E-10 >= inverse.determinant - 1.0 / determinant
                    else
                        true # contract does not apply if noninvertible
                    end
                end
            )

            isBoolean = Contract.new(
                "result must be boolean",
                Proc.new { |result| !!result == result }
            )

            addPostcondition(:isIdentity, identityDeterminant)

            addPostcondition(:isInvertable, invertibleDeterminant)

            addPostcondition(:isSquare, isBoolean)
            addPostcondition(:isDiagonal, isBoolean)
            addPostcondition(:isIdentity, isBoolean)
            addPostcondition(:isInvertable, isBoolean)
            addPostcondition(:isSingular, isBoolean)
            addPostcondition(:isZero, isBoolean)
        end

end

# This is not a ruby convention, but it's equivilant to the python version
if __FILE__ == $0
	myMAt = SparseMatrix.FromPercentFull(5, 5, 0.2)
	myMAt2 = SparseMatrix.FromPercentFull(5, 5, 0.25)
	puts "------------ Matrix 1---------------"
	puts myMAt
	puts "-------------Matrix 2---------------"
	puts myMAt2
	puts "-------------1  +   2---------------"
	puts myMAt2.add(myMAt)
	puts "-------------2  -   1---------------"
	puts myMAt2.subtract(myMAt)
	puts "-------------2  *   1---------------"
	puts myMAt2.multiply(myMAt)
	puts "-------------1  *   2---------------"
	puts myMAt2 * myMAt

	puts "-------------Matrix 3---------------"
	m = SparseMatrix.FromPercentFull(5, 5, 0.75)
	puts m
	puts "-------------  * -3  ---------------"
	puts m.multiply(-3)

	puts "=====================Square, Identity, Diagonal==============="

	ident = ContractRunner.new(SparseMatrix.Identity(10))
	puts ident
	puts "is square? " + ident.isSquare.to_s
	puts "is diagonal? " + ident.isDiagonal.to_s
	puts "is identity? " + ident.isIdentity.to_s

	ident.setElement([1,1], 3.3)
	puts ident
	puts "is square? " + ident.isSquare.to_s
	puts "is diagonal? " + ident.isDiagonal.to_s
	puts "is identity? " + ident.isIdentity.to_s

	ident.setElement([1,5], 9.3)
	puts ident
	puts "is square? " + ident.isSquare.to_s
	puts "is diagonal? " + ident.isDiagonal.to_s
	puts "is identity? " + ident.isIdentity.to_s

	ident.setDimensions([3,14])
	puts ident
	puts "is square? " + ident.isSquare.to_s
	puts "is diagonal? " + ident.isDiagonal.to_s
	puts "is identity? " + ident.isIdentity.to_s

	puts "=====================LUP Decomposition==============="

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
	puts "Determinant is: #{m.determinant} == -12?"
	puts "=====================Inversion and Related================"
	m = SparseMatrix.Zeros(3,3)
	m.setElement([1,1], 10)
	m.setElement([1,2], -9)
	m.setElement([1,3], -12)
	m.setElement([2,1], 7)
	m.setElement([2,2], -12)
	m.setElement([2,3], 11)
	m.setElement([3,1], -10)
	m.setElement([3,2], 10)
	m.setElement([3,3], 3)
	puts "---------------------- orig------------------------"
	puts m
	puts "is invertable? #{m.isInvertable}"
	puts "is singular? #{m.isSingular}"
	puts "---------------------minor-------------------------------"
	puts m.minorMatrix
	puts "---------------------adjoint-----------------------------"
	a = m.clone
	puts a.adjoint
	puts "---------------------determinant-------------------------"
	puts a.determinant
	puts "---------------------inverse-----------------------------"
	puts a.inverse
end
