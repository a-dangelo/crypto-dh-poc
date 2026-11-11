import VersoManual
import VersoBlueprint.PreviewManifest
import ExamplesBlueprint.Blueprint
open Verso Doc
open Verso.Genre Manual
def main (args : List String) : IO UInt32 :=
  Informal.PreviewManifest.blueprintMainWithPreviewData
    (%doc ExamplesBlueprint.Blueprint) args
    (extensionImpls := by exact extension_impls%)
    (config := { htmlDepth := 2, rootTocDepth := some 2 })
