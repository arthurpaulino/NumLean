import Lake
open System Lake DSL

def leanSoureDir := "NumLean"
def cppCompiler := "c++"
def cppDir : FilePath := "c"
def ffiSrc := cppDir / "ffi.c"
def ffiO := "ffi.o"
def ffiLib := "libffi.a"

def ffiOTarget (pkgDir : FilePath) : FileTarget :=
  let oFile := pkgDir / defaultBuildDir / cppDir / ffiO
  let srcTarget := inputFileTarget <| pkgDir / ffiSrc
  fileTargetWithDep oFile srcTarget fun srcFile => do
    compileO oFile srcFile
      #["-I", (← getLeanIncludeDir).toString] cppCompiler

def cLibTarget (pkgDir : FilePath) : FileTarget :=
  let libFile := pkgDir / defaultBuildDir / cppDir / ffiLib
  staticLibTarget libFile #[ffiOTarget pkgDir]

package NumLean (pkgDir) {
  srcDir := leanSoureDir
  libRoots := #[`NLTensor, `NLMatrix, `Utils]
  moreLibTargets := #[cLibTarget pkgDir]
}