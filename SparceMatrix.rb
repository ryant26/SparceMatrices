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
		nonZero.times do 
			result.setElement([rand(1..rows), rand(1..cols)], rand(1..100))
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

 	#This is to make the cholsky Factorization faster
	def colSort()
		#Idea 1: a column sorted single array, wont work
		#@matrix.keys.sort {|a, b| (a[1] * @rowCount + a[0]) <=> (b[1] * @rowCount + b[0])}.map {|x| @matrix[x]}

		#Idea 2: a list of lists, would work, but this code isnt working
		#out = Array.new(@colCount, [])
		#@matrix.each {|key, value| out[key[1]-1] << key}
		#out.each {|x| x.sort {|a,b| a[0] <=> b[0]}}
		#out.each {|x| x.map!{|y| @matrix[y]}}
		#out
	end

	def factorize()
		# this is the poor way where we iterate over values we know to be zero
		# colSort() was an attempt to fix this, but there is a trade off....
		out = clone()
		(1..@colCount).each do |j|

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
puts m.colSort