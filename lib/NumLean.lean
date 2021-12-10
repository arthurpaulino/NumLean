/-
  Copyright (c) 2021 Arthur Paulino. All rights reserved.
  Released under Apache 2.0 license as described in the file LICENSE.
  Authors: Arthur Paulino
-/

import Utils

@[extern "nl_initialize"]
constant init : BaseIO Unit

builtin_initialize init

constant NLMatrix : Type

namespace NLMatrix

@[extern "nl_matrix_new"]
constant new (nRows nCols : UInt32) (defaultValue : Float := 0.0) : IO NLMatrix

@[extern "nl_matrix_id"]
constant id (n : UInt32) : IO NLMatrix

@[extern "nl_matrix_from_values"]
constant fromValues (nRows nCols : UInt32) (values : FloatArray) : IO NLMatrix

def fromRows (rows : List FloatArray) : IO NLMatrix := do
  if rows.length = 0 then
    panic! "no data provided"
  else
    let mut values ← FloatArray.empty
    for row in rows do
      for val in row do
        values ← values.push val
    fromValues rows.length.toUInt32 (rows.get! 0).size.toUInt32 values


@[extern "nl_matrix_n_rows"]
constant nRows (m : NLMatrix) : IO UInt32

@[extern "nl_matrix_n_cols"]
constant nCols (m : NLMatrix) : IO UInt32

abbrev shapeType := UInt32 × UInt32

def shape (m : NLMatrix) : IO shapeType := do
  (← m.nRows, ← m.nCols)

@[extern "nl_matrix_get_values"]
constant getValues (m : NLMatrix) : IO (FloatArray)

@[extern "nl_matrix_get_value"]
constant getValue (m : NLMatrix) (row col : UInt32) : IO Float

@[extern "nl_matrix_transpose"]
constant transpose (m : NLMatrix) : IO NLMatrix

@[extern "nl_matrix_plus_float"]
constant plusFloat (m : NLMatrix) (f : Float) : IO NLMatrix

def minusFloat (m : NLMatrix) (f : Float) : IO NLMatrix := m.plusFloat (-1.0 * f)

@[extern "nl_matrix_times_float"]
constant timesFloat (m : NLMatrix) (f : Float) : IO NLMatrix

def divFloat (m : NLMatrix) (f : Float) : IO NLMatrix := m.timesFloat (1.0 / f)

@[extern "nl_matrix_plus_nl_matrix"]
constant plusNLMatrix (m : NLMatrix) (m' : NLMatrix) : IO NLMatrix

@[extern "nl_matrix_minus_nl_matrix"]
constant minusNLMatrix (m : NLMatrix) (m' : NLMatrix) : IO NLMatrix

@[extern "nl_matrix_times_nl_matrix"]
constant timesNLMatrix (m : NLMatrix) (m' : NLMatrix) : IO NLMatrix

def toString (m : NLMatrix) : IO String := do
  let (nRows, nCols) ← m.shape
  let nRowsNat ← nRows.toNat
  let nColsNat ← nCols.toNat
  let values ← m.getValues
  let mut lines : List (List String) ← []
  let mut colLengths : List Nat ← []
  for i in [0 : nRowsNat] do
    let mut line : List String ← []
    for j in [0 : nColsNat] do
      let v ← values.get! (j + i * nColsNat)
      let s ← v.toString.optimizeFloatString
      let sLength ← s.length
      if i = 0 then
        colLengths ← colLengths.concat sLength
      else
        if sLength > colLengths.get! j then
          colLengths ← colLengths.set j sLength
      line ← line.concat s
    lines ← lines.concat line
  let mut res ← ""
  for i in [0 : nRowsNat] do
    let line := lines.get! i
    for j in [0 : nColsNat] do
      let s := line.get! j
      res ← res ++ (s.leftFillWithUntil ' ' (colLengths.get! j)) ++ " "
      if j = nColsNat - 1 ∧ i ≠ nRowsNat - 1 then
        res ← res ++ "\n"
  res

end NLMatrix

mutual
  inductive Tensor
    | mk (head : IO NLMatrix) (steps : List TensorStep)
  inductive TensorStep
    | transpose
    | plusFloat (f : Float)
    | minusFloat (f : Float)
    | timesFloat (f : Float)
    | divFloat (f : Float)
    | plusMatrix (m : NLMatrix)
    | minusMatrix (m : NLMatrix)
    | timesMatrix (m : NLMatrix)
    | plusTensor (t : Tensor)
    | minusTensor (t : Tensor)
    | timesTensor (t : Tensor)
    deriving Inhabited
end

open NLMatrix

namespace Tensor

def new (head : NLMatrix) : Tensor := ⟨head, []⟩

def steps : Tensor → List TensorStep
| mk _ steps => steps

def head : Tensor → IO NLMatrix
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
  (s : TensorStep) : IO shapeType := do
  let shapeCurrent ← shape
  match s with
  | TensorStep.transpose     => (shapeCurrent.snd, shapeCurrent.fst)
  | TensorStep.plusMatrix m  => plusShape shapeCurrent (← m.shape)
  | TensorStep.minusMatrix m => plusShape shapeCurrent (← m.shape)
  | TensorStep.timesMatrix m => timesShape shapeCurrent (← m.shape)
  | TensorStep.plusTensor t  =>
    plusShape shapeCurrent (← t.steps.foldl computeStepShape (← t.head).shape)
  | TensorStep.minusTensor t =>
    plusShape shapeCurrent (← t.steps.foldl computeStepShape (← t.head).shape)
  | TensorStep.timesTensor t =>
    timesShape shapeCurrent (← t.steps.foldl computeStepShape (← t.head).shape)
  | _                        => shape

partial def computeStep (m : IO NLMatrix) (s : TensorStep) : IO NLMatrix := do
  match s with
  | TensorStep.transpose       => (← m).transpose
  | TensorStep.plusFloat f     => (← m).plusFloat f
  | TensorStep.minusFloat f    => (← m).minusFloat f
  | TensorStep.timesFloat f    => (← m).timesFloat f
  | TensorStep.divFloat f      => (← m).divFloat f
  | TensorStep.plusMatrix m''  => (← m).plusNLMatrix m''
  | TensorStep.minusMatrix m'' => (← m).minusNLMatrix m''
  | TensorStep.timesMatrix m'' => (← m).timesNLMatrix m''
  | TensorStep.plusTensor t    => (← m).plusNLMatrix (← t.steps.foldl computeStep t.head)
  | TensorStep.minusTensor t   => (← m).minusNLMatrix (← t.steps.foldl computeStep t.head)
  | TensorStep.timesTensor t   => (← m).timesNLMatrix (← t.steps.foldl computeStep t.head)

def computeShape (t : Tensor) : IO shapeType := do
  t.steps.foldl computeStepShape (← t.head).shape

def compute (t : Tensor) : IO NLMatrix := do
  let _ ← t.computeShape -- for validation purposes
  t.steps.foldl computeStep t.head

end Tensor

def transpose (t : Tensor) : Tensor :=
  ⟨t.head, t.steps.concat (TensorStep.transpose)⟩

def plusF (f : Float) (t : Tensor) : Tensor :=
  ⟨t.head, t.steps.concat (TensorStep.plusFloat f)⟩

def minusF (f : Float) (t : Tensor) : Tensor :=
  ⟨t.head, t.steps.concat (TensorStep.minusFloat f)⟩

def timesF (f : Float) (t : Tensor) : Tensor :=
  ⟨t.head, t.steps.concat (TensorStep.timesFloat f)⟩

def divF (f : Float) (t : Tensor) : Tensor :=
  ⟨t.head, t.steps.concat (TensorStep.divFloat f)⟩

def plusT (t' : Tensor) (t : Tensor) : Tensor :=
  ⟨t.head, t.steps.concat (TensorStep.plusTensor t')⟩

def timesT (t' : Tensor) (t : Tensor) : Tensor :=
  ⟨t.head, t.steps.concat (TensorStep.timesTensor t')⟩

def transform (t : Tensor) (f : Tensor → Tensor) : Tensor := f t

infixl:50 "↠" => transform
