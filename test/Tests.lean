import NumLean

def main : IO Unit := do
  let id ← NLMatrix.id 5
  let ones ← NLMatrix.new 5 5 1
  let t : Tensor ← Tensor.new id ↠ plusF 4 ↠ plusT (Tensor.new ones)
  let m' : NLMatrix ← t.compute
  IO.println $ ← m'.toString
