/-
  Copyright (c) 2021 Arthur Paulino. All rights reserved.
  Released under Apache 2.0 license as described in the file LICENSE.
  Authors: Arthur Paulino
-/

import NumLean

def main : IO Unit := do
  let m ← NLMatrix.id 10
  let t : Tensor := Tensor.new m ↠ plus 5.5
  let m' : NLMatrix ← t.compute
  IO.println $ ←(m'.get 1 0)
