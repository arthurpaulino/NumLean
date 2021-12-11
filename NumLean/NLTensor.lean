import NLMatrix

mutual
  inductive NLTensor
    | mk (head : IO NLMatrix) (steps : List NLTensorStep)
  inductive NLTensorStep
    | transpose
    | plusFloat (f : Float)
    | minusFloat (f : Float)
    | timesFloat (f : Float)
    | divFloat (f : Float)
    | plusMatrix (m : NLMatrix)
    | minusMatrix (m : NLMatrix)
    | timesMatrix (m : NLMatrix)
    | plusTensor (t : NLTensor)
    | minusTensor (t : NLTensor)
    | timesTensor (t : NLTensor)
    deriving Inhabited
end

open NLMatrix

namespace NLTensor

def new (head : IO NLMatrix) : NLTensor := ⟨head, []⟩

def steps : NLTensor → List NLTensorStep
| mk _ steps => steps

def head : NLTensor → IO NLMatrix
| mk head _ => head

def plusShape (shape shape' : shapeType) : shapeType :=
  if shape.fst = shape'.fst ∧ shape.snd = shape'.snd then
    shape'
  else
    panic! "inconsistent dimensions on sum"

def timesShape (shape shape' : shapeType) : shapeType :=
  if shape.snd = shape'.fst then
    (shape.fst, shape'.snd)
  else
    panic! "inconsistent dimensions on sum"

partial def computeStepShape
  (shape : IO shapeType)
  (s : NLTensorStep) : IO shapeType := do
  let shapeCurrent ← shape
  match s with
  | NLTensorStep.transpose     => (shapeCurrent.snd, shapeCurrent.fst)
  | NLTensorStep.plusMatrix m  => plusShape shapeCurrent (← m.shape)
  | NLTensorStep.minusMatrix m => plusShape shapeCurrent (← m.shape)
  | NLTensorStep.timesMatrix m => timesShape shapeCurrent (← m.shape)
  | NLTensorStep.plusTensor t  =>
    plusShape shapeCurrent (← t.steps.foldl computeStepShape (← t.head).shape)
  | NLTensorStep.minusTensor t =>
    plusShape shapeCurrent (← t.steps.foldl computeStepShape (← t.head).shape)
  | NLTensorStep.timesTensor t =>
    timesShape shapeCurrent (← t.steps.foldl computeStepShape (← t.head).shape)
  | _                        => shape

partial def computeStep (m : IO NLMatrix) (s : NLTensorStep) : IO NLMatrix := do
  match s with
  | NLTensorStep.transpose       => (← m).transpose
  | NLTensorStep.plusFloat f     => (← m).plusFloat f
  | NLTensorStep.minusFloat f    => (← m).minusFloat f
  | NLTensorStep.timesFloat f    => (← m).timesFloat f
  | NLTensorStep.divFloat f      => (← m).divFloat f
  | NLTensorStep.plusMatrix m''  => (← m).plusNLMatrix m''
  | NLTensorStep.minusMatrix m'' => (← m).minusNLMatrix m''
  | NLTensorStep.timesMatrix m'' => (← m).timesNLMatrix m''
  | NLTensorStep.plusTensor t    => (← m).plusNLMatrix (← t.steps.foldl computeStep t.head)
  | NLTensorStep.minusTensor t   => (← m).minusNLMatrix (← t.steps.foldl computeStep t.head)
  | NLTensorStep.timesTensor t   => (← m).timesNLMatrix (← t.steps.foldl computeStep t.head)

def computeShape (t : NLTensor) : IO shapeType := do
  t.steps.foldl computeStepShape (← t.head).shape

def compute (t : NLTensor) : IO NLMatrix := do
  let _ ← t.computeShape -- for validation purposes
  t.steps.foldl computeStep t.head

end NLTensor

def transpose (t : NLTensor) : NLTensor :=
  ⟨t.head, t.steps.concat (NLTensorStep.transpose)⟩

def plusF (f : Float) (t : NLTensor) : NLTensor :=
  ⟨t.head, t.steps.concat (NLTensorStep.plusFloat f)⟩

def minusF (f : Float) (t : NLTensor) : NLTensor :=
  ⟨t.head, t.steps.concat (NLTensorStep.minusFloat f)⟩

def timesF (f : Float) (t : NLTensor) : NLTensor :=
  ⟨t.head, t.steps.concat (NLTensorStep.timesFloat f)⟩

def divF (f : Float) (t : NLTensor) : NLTensor :=
  ⟨t.head, t.steps.concat (NLTensorStep.divFloat f)⟩

def plusT (t' : NLTensor) (t : NLTensor) : NLTensor :=
  ⟨t.head, t.steps.concat (NLTensorStep.plusTensor t')⟩

def timesT (t' : NLTensor) (t : NLTensor) : NLTensor :=
  ⟨t.head, t.steps.concat (NLTensorStep.timesTensor t')⟩

def transform (t : NLTensor) (f : NLTensor → NLTensor) : NLTensor := f t

infixl:50 "↠" => transform
