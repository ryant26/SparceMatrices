require 'minitest'

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
class SparseMatrix
	protected
	attr_reader :matrix

	private
	@rowCount
	@colCount

	# --------------------Factory Methods-------------------------
	def self.CreateMatrixFromPercentFull(rows, cols, percent)
		result = SparseMatrix.Zeros(rows, cols)
		nonZero = (rows * cols * percent).floor
		random = Random.new
		nonZero.times do 
			result.setElement([random.rand(rows), random.rand(cols)], random.rand(0..100))
		end
		result
	end

	def self.CreateTridiagonal(height, width)end

	def self.Zeros(height, width)
		SparseMatrix.new(height, width)
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
	end

	# ----------------------------Arithmatic-------------------------------

	# Should scalar add turn the sparse matrix into a normal one? Or simply add to the non-zero elem?
	def add(matrix)
		result = clone
		result.sparseMerge!(matrix) { |key, oldval, newval| oldval + newval }
		return result
	end
	
	# Should scalar sub turn the sparse matrix into a normal one? Or simply sub from the non-zero elem?
	def subtract(matrix)
		result = clone
		result.sparseMerge!(matrix) { |key, oldval, newval| oldval - newval }
		return result
	end

	def multiply(matrix)
		result = clone
		if matrix.respond_to? :getElement
			result.matrix.each { |key, value| result.setElement(key, matrix.getElement(key) * value)}
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
		@rowCount.times do |i|
			print "| "
			@colCount.times do |j|
				print "#{getElement([i,j])} "
			end
			puts "|"
		end
	end

	# scales to large matrices without creating huge strings - zeros omitted
	# prints coordinate value pairs sorted by coordinate, i,j : <val>
	def to_s_minimal
		str = ""
		@matrix.each { |key, val| str += "TODO" }
		str
	end

	# ------------------------------Infastructure-----------------------------

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

end


myMAt = SparseMatrix.CreateMatrixFromPercentFull(5, 5, 0.5)
myMAt2 = SparseMatrix.CreateMatrixFromPercentFull(5, 5, 0.25)
puts "------------ Matrix 1---------------"
puts myMAt
puts "-------------Matrix 2---------------"
puts myMAt2
puts "-------------1  +   2---------------"
puts myMAt2.add(myMAt)
puts "-------------2  -   1---------------"
puts myMAt2.subtract(myMAt)

puts "-------------Matrix 3---------------"
m = SparseMatrix.CreateMatrixFromPercentFull(5, 5, 0.75)
puts m
puts "-------------  * -3  ---------------"
puts m.multiply(-3)
