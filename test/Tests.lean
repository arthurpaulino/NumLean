import NLMatrix
import NLTensor

def main : IO Unit := do
  let id := NLMatrix.id 5
  let ones := NLMatrix.new 5 5 1
  let sum ← id + ones
  IO.println $ ← sum.toString
  IO.println "-------------------"
  let t : NLTensor ← NLTensor.new id ↠ plusF 3
    ↠ plusT (NLTensor.new ones ↠ plusF 1)
  let m' : NLMatrix ← t.compute
  IO.println $ ← m'.toString
  IO.println "-------------------"
  let m'' ← NLMatrix.fromRows [[1, 2], [4, 5]]
  IO.println $ ← m''.toString
