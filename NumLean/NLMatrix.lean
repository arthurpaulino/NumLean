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
constant plusNLMatrix (m m' : NLMatrix) : IO NLMatrix

@[extern "nl_matrix_minus_nl_matrix"]
constant minusNLMatrix (m m': NLMatrix) : IO NLMatrix

@[extern "nl_matrix_times_nl_matrix"]
constant timesNLMatrix (m m': NLMatrix) : IO NLMatrix

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

def plusNLMatrix' (m m': IO NLMatrix) : IO NLMatrix := do
  (←m).plusNLMatrix (←m')

def minusNLMatrix' (m m': IO NLMatrix) : IO NLMatrix := do
  (←m).minusNLMatrix (←m')

def timesNLMatrix' (m m': IO NLMatrix) : IO NLMatrix := do
  (←m).timesNLMatrix (←m')

instance : Add (IO NLMatrix) := ⟨plusNLMatrix'⟩
instance : Sub (IO NLMatrix) := ⟨minusNLMatrix'⟩
instance : Mul (IO NLMatrix) := ⟨timesNLMatrix'⟩

end NLMatrix
