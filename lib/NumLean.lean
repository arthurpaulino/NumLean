/-
  Copyright (c) 2021 Arthur Paulino. All rights reserved.
  Released under Apache 2.0 license as described in the file LICENSE.
  Authors: Arthur Paulino
-/

import Utils

@[extern "nl_initialize"]
constant init : BaseIO Unit

builtin_initialize init

universe u

constant NLMatrix : Type

namespace NLMatrix

@[extern "nl_matrix_new"]
constant new (nRows nCols : UInt32) (defaultValue : Float := 0.0) : IO NLMatrix

@[extern "nl_matrix_id"]
constant id (n : UInt32) : IO NLMatrix

@[extern "nl_matrix_n_rows"]
constant nRows (m : NLMatrix) : IO UInt32

@[extern "nl_matrix_n_cols"]
constant nCols (m : NLMatrix) : IO UInt32

def shape (m : NLMatrix) : IO (UInt32 × UInt32) := do
  (← m.nRows, ← m.nCols)

-- todo: segmentation fault
-- @[extern "nl_matrix_get_values"]
-- constant getValues (m : NLMatrix) : IO (Array Float)

@[extern "nl_matrix_get_value"]
constant getValue (m : NLMatrix) (row col : UInt32) : IO Float

@[extern "nl_matrix_plus_float"]
constant plusFloat (m : NLMatrix) (f : Float) : IO NLMatrix

def minusFloat (m : NLMatrix) (f : Float) : IO NLMatrix := m.plusFloat (-1.0 * f)

@[extern "nl_matrix_times_float"]
constant timesFloat (m : NLMatrix) (f : Float) : IO NLMatrix

def divFloat (m : NLMatrix) (f : Float) : IO NLMatrix := m.timesFloat (1.0 / f)

@[extern "nl_matrix_plus_nl_matrix"]
constant plusNLMatrix (m : NLMatrix) (m' : NLMatrix) : IO NLMatrix

@[extern "nl_matrix_times_nl_matrix"]
constant timesNLMatrix (m : NLMatrix) (m' : NLMatrix) : IO NLMatrix

def toString (m : NLMatrix) : IO String := do
  let (nRows, nCols) ← m.shape
  let nRowsNat ← nRows.toNat
  let nColsNat ← nCols.toNat
  let mut lines : List (List String) ← []
  let mut colLengths : List Nat ← []
  for i in [0 : nRowsNat] do
    let mut line : List String ← []
    for j in [0 : nColsNat] do
      -- todo: use getValues to decrease communication overhead
      let v ← m.getValue i.toUInt32 j.toUInt32
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
    | plusFloat (f : Float)
    | minusFloat (f : Float)
    | timesFloat (f : Float)
    | divFloat (f : Float)
    | plusTensor (t : Tensor)
    | timesTensor (t : Tensor)
    deriving Inhabited
end

namespace Tensor

def new (head : NLMatrix) : Tensor := ⟨head, []⟩

def steps : Tensor → List TensorStep
| mk _ steps => steps

def head : Tensor → IO NLMatrix
| mk head _ => head

partial def computeStepShape
  (shape : IO (UInt32 × UInt32))
  (s : TensorStep) : IO (UInt32 × UInt32) := do
  let shape' ← shape
  match s with
  | TensorStep.plusTensor t =>
    let tShape ← t.steps.foldl computeStepShape (← t.head).shape
    if shape'.fst = tShape.fst ∧ shape'.snd = tShape.snd then
      shape'
    else
      panic! "inconsistent dimensions on sum"
  | TensorStep.timesTensor t =>
    let tShape ← t.steps.foldl computeStepShape (← t.head).shape
    if shape'.snd = tShape.fst then
      (shape'.fst, tShape.snd)
    else
      panic! "inconsistent dimensions on product"
  | _ => shape

partial def computeStep (m : IO NLMatrix) (s : TensorStep) : IO NLMatrix := do
  let m' : NLMatrix ← m
  match s with
  | TensorStep.plusFloat f  => m'.plusFloat f
  | TensorStep.minusFloat f => m'.minusFloat f
  | TensorStep.timesFloat f => m'.timesFloat f
  | TensorStep.divFloat f   => m'.divFloat f
  | TensorStep.plusTensor t =>
    let t' : NLMatrix ← (t.steps.foldl computeStep t.head)
    m'.plusNLMatrix t'
  | TensorStep.timesTensor t =>
    let t' : NLMatrix ← (t.steps.foldl computeStep t.head)
    m'.timesNLMatrix t'

def computeShape (t : Tensor) : IO (UInt32 × UInt32) := do
  t.steps.foldl computeStepShape (← t.head).shape

def compute (t : Tensor) : IO NLMatrix := do
  let _ ← t.computeShape -- for validation purposes
  t.steps.foldl computeStep t.head

end Tensor

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
