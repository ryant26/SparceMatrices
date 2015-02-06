# SparceMatrices

## newDirection Branch
- We no longer support operations with scalars except multiply (This is how the Ruby matrix class works)

- We aren't compatible with the ruby matrix class
	- If a dense matrix is created through some order of operations, you simply loose the benifits
	of sparseness, and countinue with our subset of opperations and use our algorithms.

- We don't have a factory, we have 'Factory Methods' all my research on the web has pointed to this being the ruby standard