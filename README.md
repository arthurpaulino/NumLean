# NumLean

An early WIP of a numerical lib for Lean 4.

This package provides an interface to low level matricial operations.

## Matrix instantiation

```lean
let ones ← NLMatrix.new 5 5 1                 -- creates a 5×5 matrix filled with ones
let id ← NLMatrix.id 5                        -- creates a 5×5 identity matrix
let m' ← NLMatrix.fromValues 2 2 [1, 2, 3, 4] -- creates a 2×2 matrix with those values
let m'' ← NLMatrix.fromRows [[1, 2], [3, 4]]  -- creates a 2×2 matrix similar to m'
```

## Tensors

It's also possible to stack matrix operations with `NLTensor`. A tensor always starts
with a matrix in the head.

```lean
let t : NLTensor ← NLTensor.new id ↠ plusF 3
  ↠ plusT (NLTensor.new ones ↠ plusF 3)
-- `t` represents the process of adding 3.0 to `id` and then
-- summing the result with `ones`

let tResult : NLMatrix ← t.compute
-- checks for dimensionality consistency and then performs the computations

IO.println $ ← m'.toString
-- 6.0 5.0 5.0 5.0 5.0 
-- 5.0 6.0 5.0 5.0 5.0 
-- 5.0 5.0 6.0 5.0 5.0 
-- 5.0 5.0 5.0 6.0 5.0 
-- 5.0 5.0 5.0 5.0 6.0
```

This abstraction allows you to create functions that chains transformations without
duplicating code.

## Next steps

* Optimize representation for some special kinds of matrices
* Optimize operations for such special matrices
* Provide more operations like determinant, inverse etc
* Masking/broadcasting
* Documentation
* Dream: plug in more powerful backend like CUDA

## Contributing

Feel free to create issues, but please be responsive after doing so. You can also reach
me on [Zulip](https://leanprover.zulipchat.com/).

Fork and open PRs as you wish. But again, be responsive after doing so :)
