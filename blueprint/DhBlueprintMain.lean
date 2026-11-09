import VersoManual
import VersoBlueprint.PreviewManifest
import DhBlueprint.Blueprint
open Verso Doc
open Verso.Genre Manual
def main (args : List String) : IO UInt32 :=
  Informal.PreviewManifest.blueprintMainWithPreviewData
    (%doc DhBlueprint.Blueprint) args
    (extensionImpls := by exact extension_impls%)
    (config := { htmlDepth := 1, rootTocDepth := some 1 })
