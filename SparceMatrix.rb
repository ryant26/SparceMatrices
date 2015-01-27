# This is the begging of the sparce matrix class
# Wanted to start to get a feeling of how it was going to work

# add and subtract are working (Without and pre or post checks)
	# when adding matricies of the same size


class SparceMatrix
	attr_reader :matrix
	private
	@dimension


	# returns true and yields a block if the passed point has nonzero value
	def nonZero?(point)
		return false unless @matrix.key?point

		yield if block_given?
		true
	end

	def zero?(point)
		return false unless nonZero? (point)

		yield if block_given?
		true
	end

	public
	def initialize(dim, nonZero=dim/2)
		@dimension = dim
		@matrix = Hash.new
		nonZero.times do
			while (true) do
				x = Random.rand(nonZero)
				y = Random.rand(nonZero)
				if @matrix.include?([x, y])
					next
				else
					# HARD CODED LIMIT OF THE NON-ZERO VALUES
					@matrix[[x, y]] = Random.rand(10)
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

	def to_s
		#This looks bad when there are long (many digit) non-zero elements
		@dimension.times do |x|
			print "|"
			@dimension.times do |y|
				print @matrix.has_key?([x, y]) ? @matrix[[x, y]] : "0"
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
