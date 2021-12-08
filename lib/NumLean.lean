/-
  Copyright (c) 2021 Arthur Paulino. All rights reserved.
  Released under Apache 2.0 license as described in the file LICENSE.
  Authors: Arthur Paulino
-/

@[extern "nl_initialize"]
constant init : BaseIO Unit

builtin_initialize init

universe u

constant NLArray : Type

namespace NLArray

@[extern "nl_array_mk"]
constant mk (length : UInt64) : IO NLArray

-- @[extern "nl_array_to_lean_array"]
-- constant toArray (a : NLArray) : Array Float

@[extern "nl_array_plus_float"]
constant plusFloat (a : NLArray) (f : Float) : IO Unit

def minusFloat (a : NLArray) (f : Float) : IO Unit := a.plusFloat (-1.0 * f)

@[extern "nl_array_times_float"]
constant timesFloat (a : NLArray) (f : Float) : IO Unit

def divFloat (a : NLArray) (f : Float) : IO Unit := a.timesFloat (1.0 / f)

end NLArray

mutual
  inductive Tensor
    | mk (head : NLArray) (steps : List TensorStep)
  inductive TensorStep
    | plusFloat (f : Float)
    | minusFloat (f : Float)
    | timesFloat (f : Float)
    | divFloat (f : Float)
    deriving Inhabited
end

namespace Tensor

def new (head : NLArray) : Tensor := ⟨head, []⟩

def steps : Tensor → List TensorStep
| mk _ steps => steps

def head : Tensor → NLArray
| mk head _ => head

def compute (t : Tensor) : IO Unit :=
  for step in t.steps do
    match step with
    | TensorStep.plusFloat f => t.head.plusFloat f
    | TensorStep.minusFloat f => t.head.minusFloat f
    | TensorStep.timesFloat f => t.head.timesFloat f
    | TensorStep.divFloat f => t.head.divFloat f

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
