/-
  Copyright (c) 2021 Arthur Paulino. All rights reserved.
  Released under Apache 2.0 license as described in the file LICENSE.
  Authors: Arthur Paulino
-/

import NumLean

def main : IO Unit := do
  let id ← NLMatrix.id 5
  -- let ones ← NLMatrix.new 5 5 1
  let t : Tensor ← Tensor.new id ↠ plusF 4 ↠ plusF 6.0
  let m' : NLMatrix ← t.compute
  IO.println $ ← m'.toString
-- 11.0 10.0 10.0 10.0 10.0 
-- 10.0 10.0  6.0  6.0  6.0 ← these 6's are bugs
-- 10.0 10.0 11.0 10.0 10.0 
-- 10.0 10.0 10.0 11.0 10.0 
-- 10.0 10.0 10.0 10.0 11.0
