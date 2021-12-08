/-
  Copyright (c) 2021 Arthur Paulino. All rights reserved.
  Released under Apache 2.0 license as described in the file LICENSE.
  Authors: Arthur Paulino
-/

@[extern "nl_initialize"]
constant init : BaseIO Unit

builtin_initialize init

universe u

constant NLMatrix : Type

namespace NLMatrix

@[extern "nl_matrix_new"]
constant new (nRows nCols : UInt64) (defaultValue : Float := 0.0) : IO NLMatrix

@[extern "nl_matrix_id"]
constant id (n : UInt64) : IO NLMatrix

@[extern "nl_matrix_n_rows"]
constant nRows (m : NLMatrix) : IO UInt64

@[extern "nl_matrix_n_cols"]
constant nCols (m : NLMatrix) : IO UInt64

@[extern "nl_matrix_get"]
constant get (m : NLMatrix) (row col : UInt64) : IO Float

@[extern "nl_matrix_plus_float"]
constant plusFloat (m : NLMatrix) (f : Float) : IO NLMatrix

def minusFloat (m : NLMatrix) (f : Float) : IO NLMatrix := m.plusFloat (-1.0 * f)

@[extern "nl_matrix_times_float"]
constant timesFloat (m : NLMatrix) (f : Float) : IO NLMatrix

def divFloat (m : NLMatrix) (f : Float) : IO NLMatrix := m.timesFloat (1.0 / f)

def toString (m : NLMatrix) : IO String := do
  let nRows ← m.nRows
  let nCols ← m.nCols
  let mut res : String := ""
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
    deriving Inhabited
end

namespace Tensor

def new (head : NLMatrix) : Tensor := ⟨head, []⟩

def steps : Tensor → List TensorStep
| mk _ steps => steps

def head : Tensor → IO NLMatrix
| mk head _ => head

def applyStep (m : IO NLMatrix) (s : TensorStep) : IO NLMatrix := do
  let m' : NLMatrix ← m
  match s with
  | TensorStep.plusFloat f => m'.plusFloat f
  | TensorStep.minusFloat f => m'.minusFloat f
  | TensorStep.timesFloat f => m'.timesFloat f
  | TensorStep.divFloat f => m'.divFloat f

def compute (t : Tensor) : IO NLMatrix :=
  t.steps.foldl applyStep t.head

end Tensor

def plus (f : Float) (t : Tensor) : Tensor :=
  ⟨t.head, t.steps.concat (TensorStep.plusFloat f)⟩

def minus (f : Float) (t : Tensor) : Tensor :=
  ⟨t.head, t.steps.concat (TensorStep.minusFloat f)⟩

def times (f : Float) (t : Tensor) : Tensor :=
  ⟨t.head, t.steps.concat (TensorStep.timesFloat f)⟩

def div (f : Float) (t : Tensor) : Tensor :=
  ⟨t.head, t.steps.concat (TensorStep.divFloat f)⟩

def transform (t : Tensor) (f : Tensor → Tensor) : Tensor := f t

infixl:50 "↠" => transform
