import DhBlueprint.Blueprint
import SchnorrBlueprint.Blueprint
import HashCommitmentBlueprint.Blueprint
import VersoBlueprint.Commands.Graph
import VersoBlueprint.Commands.Summary
open Verso.Genre Verso.Genre.Manual Informal
#doc (Manual) "Verified cryptography examples" =>

Rust programs, extracted Lean semantics, and explicit security arguments.
Each chapter keeps its source and proof development in a separate `Examples/` directory.
The chapters share this book, navigation, and dependency graph.

{include 0 DhBlueprint.Blueprint}
{include 0 SchnorrBlueprint.Blueprint}
{include 0 HashCommitmentBlueprint.Blueprint}

{blueprint_graph (direction := LR)}
{blueprint_summary}
