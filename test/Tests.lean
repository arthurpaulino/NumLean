import NLMatrix
import NLTensor

def main : IO Unit := do
  let id ← NLMatrix.id 5
  let ones ← NLMatrix.new 5 5 1
  let t : NLTensor ← NLTensor.new id ↠ plusF 4 ↠ plusT (NLTensor.new ones)
  let m' : NLMatrix ← t.compute
  IO.println $ ← m'.toString
  let m'' ← NLMatrix.fromRows [[1, 2], [4, 5]]
  IO.println $ ← m''.toString
