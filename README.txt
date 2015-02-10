# SparceMatrices

## Usage

Initialization

FromPercentFull(rows, cols, percent)
Zeros(rows, cols)
Identity(size)
FromHash(input, rows, columns)
Build(height, width)  { |row, col|  # element }

Arithmetic

add(matrix)
subtract(matrix)
multiply(matrix)
multiply!(matrix)

Transformations

inverse()
inverse!()
transpose()
transpose!()
resize(rows, columns)
resize!(rows, columns)

Properties

isSquare
isDiagonal
isIdentity
isInvertable
isSingular
isZero

Other

adjoint()
cofactorMatrix()
minorMatrix()
determinant()

Utilities

setElement(key, value)
getElement(key)
setData(matrix)
clone()
