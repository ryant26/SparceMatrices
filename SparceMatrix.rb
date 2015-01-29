# This is the begging of the sparce matrix class
# Wanted to start to get a feeling of how it was going to work

# add and subtract are working (Without and pre or post checks)
	# when adding matricies of the same size

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
class SparceMatrix
	attr_reader :matrix
	private
	@rowCount
	@colCount

	# returns true and yields a block if the passed point has nonzero value
	def nonZero?(point)
		return false unless @matrix.key?point

		yield if block_given?
		true
	end

	# returns true and yields a block if the passed point has zero value
	def zero?(point)
		return false unless nonZero? (point)

		yield if block_given?
		true
	end

	# precond
	# 	dim must be an integer > 1 or a 2-member array of integer > 1
	# postcond
	# 	will set the instance members rowCount and colCount
	private
	def setDimensions(dim)
		# inspect dimension
		if dim.is_a? Array
			@rowCount, @colCount = dim[0], dim[1]
		else
			@rowCount, @colCount = dim, dim
		end
	end

	# precond
	# 	dim must be supplied.  see setDimensions precond
	# postcond
	# 	
	# note
	# 	rather than boolean switches and overloaded methods for initialization,
	# 	factory pattern should be employed: (separate class? SparseFactory?)
	# 	- .newMatrix(rowCount, colCount)
	# 	- .newSquare(size)
	# 	- .newIdentity(size) # implicitly square
	# 	- .newTridiagonal(size) # returns subclass!!
	# 		- 
	# 	also, a randomly populated matrix initializer is likely of
	# 	limited value beyond initial testing.
	public
	def initialize(dim, nonZero=nil)

		setDimensions(dim)

		@matrix = Hash.new

		puts @rowCount
		puts @colCount

		(nonZero ? nonZero : @rowCount * @colCount / 2).times do
			while (true) do
				i = Random.rand(@rowCount)
				j = Random.rand(@colCount)
				if @matrix.include?([i, j])
					next
				else
					# HARD CODED LIMIT OF THE NON-ZERO VALUES
					@matrix[[i, j]] = Random.rand(10)
					break
				end
			end
		end
	end

	# Identical to hash.merge!, but clears zero values from map
	def sparseMerge!(matrix)
		matrix.matrix.each do |key, val|
			# 
			if @matrix.key?(key)
				new = yield key, @matrix[key], val
				# set new value or delete if new value is zero
				if new == 0
					@matrix.delete(key)
				else
					@matrix[key] = new
				end
			else
				new = yield key, 0, val
				# set new value if nonzero
				@matrix[key] = new unless new == 0
			end
		end
	end

	def add(matrix)
		sparseMerge!(matrix) { |key, oldval, newval| oldval + newval }
	end

	def subtract(matrix)
		sparseMerge!(matrix) { |key, oldval, newval| oldval - newval }
	end

	# Multiplies each value of the matrix by the scalar
	def scalarMultiply(scalar)
		if scalar == 0
			@matrix = {} 
		else
			@matrix.each { |key, val| @matrix[key] = val * scalar }
		end
	end

	# scales to large matrices without creating huge strings - zeros omitted
	# prints coordinate value pairs sorted by coordinate, i,j : <val>
	def to_s_minimal
		str = ""
		@matrix.each { |key, val| str += "TODO" }
		str
	end

	# does not scale to large sparse matrices - all values printed
	def to_s
		#This looks bad when there are long (many digit) non-zero elements
		@rowCount.times do |i|
			print "|"
			@colCount.times do |j|
				print @matrix.has_key?([i, j]) ? @matrix[[i, j]] : "0"
				print " "
			end
			puts "|"
		end
	end

end


myMAt = SparceMatrix.new(5)
myMAt2 = SparceMatrix.new(5)
puts "------------ Matrix 1---------------"
puts myMAt
puts "-------------Matrix 2---------------"
puts myMAt2
puts "-------------1  +   2---------------"
myMAt2.add(myMAt)
puts myMAt2
puts "-------------2  -   1---------------"
myMAt2.subtract(myMAt)
puts myMAt2


puts "-------------Matrix 3---------------"
m = SparceMatrix.new(5)
puts m
puts "-------------  * -3  ---------------"
m.scalarMultiply(-3)
puts m
