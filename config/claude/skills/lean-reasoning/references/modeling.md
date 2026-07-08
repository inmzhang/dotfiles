# Modeling: target-language constructs → Lean 4 (core only)

The goal of every pattern here is a *small translation gap*: the Lean model should mirror the target's structure so closely that a reviewer can diff them mentally. Prefer the faithful-but-clunky translation over the elegant-but-different one — elegance in the model is a form of gap.

## Integers

| Target | Faithful model | Idealized model |
|--------|----------------|-----------------|
| `u8/u16/u32/u64` | `UInt8/UInt16/UInt32/UInt64` or `BitVec 8/16/32/64` | `Nat` |
| `i8/i16/i32/i64` | `Int8/Int16/Int32/Int64` or `BitVec n` (two's complement) | `Int` |
| unbounded (Python `int`) | `Int` / `Nat` — already exact | — |

Choose deliberately and record the choice in the fidelity notes:

- **Idealized (`Nat`/`Int`)** when the question is about the algorithm's logic and overflow is out of scope. Beware `Nat` subtraction truncating at zero (`3 - 5 = 0`) — it silently diverges from signed targets; use `Int` when the target can go negative.
- **Faithful (`BitVec n` / `UIntN`)** when the question involves overflow, wrapping, or bit tricks. `BitVec` arithmetic wraps exactly like machine integers, and `bv_decide` proves properties over *all* values of the width (see techniques.md).

## Mutation, loops, early return

Lean's `Id.run do` gives real mutable locals, `for` loops, and early `return` — translate imperative code nearly line-by-line instead of contorting it into folds:

```lean
-- C:  int sum_pos(int *a, int n) { int s = 0; for (...) if (a[i] > 0) s += a[i]; return s; }
def sumPos (a : Array Int) : Int := Id.run do
  let mut s : Int := 0
  for x in a do
    if x > 0 then
      s := s + x
  return s
```

`break`, `continue`, `if ... then return`, and range loops `for i in [0:n]` all work. The result is still a pure function — `#eval`, `decide`, and theorems apply as usual (definitions unfold via `simp [sumPos, Id.run]` or, more often, are handled by `grind`/`fun_induction`).

## `while` loops and termination

A `while cond` loop has no bound Lean can see. Two options:

1. **Recast as bounded recursion** with `termination_by` when a decreasing measure is evident.
2. **Fuel pattern** — thread an explicit iteration budget; faithful to "this loop terminates in practice" and keeps the function transparent to proofs:

```lean
def loop (fuel : Nat) (state : S) : Option S :=
  match fuel with
  | 0 => none                        -- fuel exhausted: distinguishable from success
  | fuel + 1 =>
    if done state then some state
    else loop fuel (step state)
```

Claims then quantify over "enough fuel". Avoid `partial def` when the function must be reasoned about: it compiles and `#eval`s, but is opaque to `decide` and theorems.

## Other constructs

| Target construct | Lean model |
|------------------|------------|
| `null` / `None` / nullable | `Option α` |
| exceptions / `Result` | `Except ε α` (or `Option` when the error payload is irrelevant) |
| struct / record / dataclass | `structure ... deriving Repr, DecidableEq` |
| enum / tagged union | `inductive ... deriving Repr, DecidableEq` |
| array / list / vector | `Array α` (indexed access, mirrors imperative code) or `List α` (recursion-friendly) |
| hash map / dict | `Std.HashMap` (`import Std`) — or model as `List (k × v)` when only a few ops are used |
| string | `String` / `List Char` (core `String` API is decent) |
| generics | polymorphic `def f (α : Type) ...` or type classes |
| global state | extra parameter threaded through, or `StateM` inside `Id.run do` |

`deriving Repr` makes `#eval` output readable; `deriving DecidableEq` makes `decide` and `==` work on your types. Add both to every model type by default.

## Floats

Lean `Float` is IEEE-754 and `#eval`s fine, but there is no `decide` for float claims and no core theory of rounding. If the question is really about exact structure (integer grid, fixed-point, comparisons), remodel with `Int`-scaled values and note it. If the question is genuinely about floating-point behavior, this skill's guarantee gets weak — say so rather than over-claim.

## Indexing and panics

Lean array access `a[i]!` panics like the target would; `a[i]?` returns `Option`; `a[i]` requires an in-bounds proof. For modeling, `a[i]!` mirrors the target most closely and keeps code readable; switch to `a[i]?` when the *claim* is about out-of-bounds behavior. A `#eval` that panics is itself a finding.

## Worked micro-example

Target (Python):

```python
def merge(a, b):        # merge two sorted lists
    i = j = 0; out = []
    while i < len(a) and j < len(b):
        if a[i] <= b[j]: out.append(a[i]); i += 1
        else:            out.append(b[j]); j += 1
    return out + a[i:] + b[j:]
```

Model (structurally recursive on both lists — the standard shape for merge):

```lean
def merge : List Int → List Int → List Int
  | [], ys => ys
  | xs, [] => xs
  | x :: xs, y :: ys =>
    if x ≤ y then x :: merge xs (y :: ys)
    else y :: merge (x :: xs) ys
```

Here the recursion *is* the while loop's structure; fidelity note: "indices i/j replaced by list de-structuring — same visit order."
