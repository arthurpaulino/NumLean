/-
  Copyright (c) 2021 Arthur Paulino. All rights reserved.
  Released under Apache 2.0 license as described in the file LICENSE.
  Authors: Arthur Paulino
-/

import NumLean

def main : IO Unit := do
  let arr ← NLArray.mk 10
  let t := Tensor.new arr ↠ plus 5.0 ↠ times 10.0
  t.compute
