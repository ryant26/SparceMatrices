# This is the begging of the sparce matrix class
# Wanted to start to get a feeling of how it was going to work

# add and subtract are working (Without and pre or post checks)
	# when adding matricies of the same size


class SparceMatrix
	private
	@matrix
	@dimension

	# These 2 are pretty bad, should be 1-liners, considder refactoring
	def nonZero?(point)
		if @matrix.key?point
			yield if block_given?
			true
		else
			false
		end
	end

	def zero?(point)
		if nonZero? (point)
			true
		else
			yield if block_given?
			false
		end
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

	def add(matrix)
		@matrix.merge!(matrix.getDataBacking) { |key, oldval, newval| oldval + newval }
	end

	def subtract(matrix)
		# Doesn't check if the subtraction makes an element 0
		# if it does it should be taken out of the hash
		matrix.getDataBacking.each do |key, value|
			nonZero?(key) { @matrix[key] -= value}
			zero?(key) {@matrix[key] = -value}
		end
	end

	def getDataBacking
		@matrix
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