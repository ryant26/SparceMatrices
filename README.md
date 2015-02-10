# SparceMatrices

## Things to think about
- Refactoring, if we have time

## Eigan Values
- The algorithms for eigan values are not trivial. Infact producing exact eigan values for matrices larger than 4x4 is impossible. We can only get approximations that get more accuracte with more iterations. (http://en.wikipedia.org/wiki/Eigenvalue_algorithm)

- Ruby matrix has an eigan system function we could delegate to if we really want our library to offer this?

## Rank
- Again, not a trivial problem when a matrix starts to get large. I don't think its feasable for us to implement this.
- Again, the ruby matrix class offers this if we'd like to delegate