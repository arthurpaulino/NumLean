/-
  Copyright (c) 2021 Arthur Paulino. All rights reserved.
  Released under Apache 2.0 license as described in the file LICENSE.
  Authors: Arthur Paulino
-/

namespace String

def withoutRightmostZeros (s : String) : String := Id.run do
  if s ≠ "" then
    let data := s.data
    let mut rangeList : List Nat := []
    for i in [0 : data.length] do
      rangeList := rangeList.concat i
    for i in rangeList.reverse do
      if i = 0 then
        return ""
      if (data.get! i) ≠ '0' then
        let sub : Substring := ⟨s, 0, i + 1⟩
        return sub.toString
    s
  else
    s

def optimizeFloatString (s : String) : String :=
  let split := s.splitOn "."
  let length := split.length
  if length = 1 then
    s
  else
    if length = 2 then
      let cleanR := split.getLast!.withoutRightmostZeros
      split.head! ++ "." ++ (if cleanR.isEmpty then "0" else cleanR)
    else
      panic! "ill-formed float string"

def leftFillWithUntil (s : String) (f : Char) (n : Nat) : String := Id.run do
  let mut data : List Char := s.data
  for _ in [0 : n - s.length] do
    data := [f].append data
  ⟨data⟩

end String

namespace Array

instance : Coe (Array Float) FloatArray where
  coe arr := Id.run do
    let mut fArr := FloatArray.empty
    for f in arr.data do
      fArr := fArr.push f
    fArr

instance : Coe (Array Nat) FloatArray where
  coe arr := Id.run do
    let mut fArr := FloatArray.empty
    for f in arr.data do
      fArr := fArr.push f.toFloat
    fArr

end Array

namespace List

instance : Coe (List Float) FloatArray where
  coe := toFloatArray

instance : Coe (List Nat) FloatArray where
  coe l := (l.map λ n => n.toFloat).toFloatArray

end List

