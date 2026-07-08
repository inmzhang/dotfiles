# Verification techniques (core Lean 4, single file)

## Contents
- [Counterexample search](#counterexample-search)
- [Equivalence of two implementations](#equivalence-of-two-implementations)
- [Bit-level verification with bv_decide](#bit-level-verification-with-bv_decide)
- [Invariant preservation](#invariant-preservation)
- [Complexity via cost models](#complexity-via-cost-models)
- [Core tactic cheatsheet](#core-tactic-cheatsheet)
- [Troubleshooting](#troubleshooting)

## Counterexample search

The highest-value move for bug hunting: instead of arguing the code is wrong, make the compiler *produce* the failing input.

```lean
-- single argument
#eval (List.range 2000).filter (fun n => spec n ≠ impl n) |>.take 5

-- pairs (e.g. two lengths, two indices)
#eval do
  let mut bad := #[]
  for a in List.range 100 do
    for b in List.range 100 do
      if spec a b ≠ impl a b then bad := bad.push (a, b)
  return bad.take 5

-- structured inputs: enumerate small lists
def listsUpTo (len maxVal : Nat) : List (List Nat) :=
  match len with
  | 0 => [[]]
  | n + 1 => (listsUpTo n maxVal).flatMap fun t =>
      (List.range maxVal).map (· :: t) ++ [t]
def prop (l : List Nat) : Bool := ...   -- write search predicates as Bool, not Prop
#eval (listsUpTo 4 5).filter (fun l => !prop l) |>.take 3
```

Empty result over a well-chosen domain → upgrade to a `decide` claim (rung 2) to make it part of the checked artifact. Non-empty → **REFUTED**; shrink the counterexample by hand (smallest n that fails), map it back to concrete target-language input, and when practical confirm against the real code.

Choose the domain to cover the *boundaries* the target code touches: 0, 1, sizes around every literal in the code, equal/adjacent pairs. An exhaustive check over all n < 1000 that excludes the empty case proves nothing about the empty case.

## Equivalence of two implementations

The refactor-safety workhorse. State it, then climb the ladder:

```lean
-- rung 2: exhaustive on a finite domain
example : (List.range 5000).all (fun n => fast n == slow n) := by native_decide

-- rung 3: full proof, typically by the recursion structure of one side
theorem fast_eq_slow : ∀ n, fast n = slow n := by
  intro n
  induction n with
  | zero => rfl
  | succ k ih => simp [fast, slow, Nat.succ_mul, Nat.mul_succ, ← ih]; omega
```

Proof strategy: induct on whatever the recursive implementation recurses on (`induction n`, `induction xs`, or `fun_induction slow` to follow a non-structural recursion). Close arithmetic leaves with `omega` (linear) or `grind`; unfold definitions with `simp [f, g]`. If the full proof resists after a few attempts, report the strongest finite check you achieved instead — FINITE-CHECKED on 10⁴ inputs plus the boundary cases is an honest, useful verdict.

For functions on machine integers, prefer the `bv_decide` route below — it covers *all* inputs of the width, not a sampled range.

## Bit-level verification with bv_decide

`bv_decide` (core, SAT-backed) decides goals over `BitVec n` — universally, all 2ⁿ values, in seconds. This makes bit-twiddling verification essentially free:

```lean
import Std.Tactic.BVDecide

-- "n & (n-1) clears the lowest set bit" — verified for all 2³² values of n
example (n : BitVec 32) : n &&& (n - 1) = n - (n &&& -n) := by bv_decide

-- branchless abs via sign-extension trick
example (x : BitVec 32) :
    (x ^^^ x.sshiftRight 31) - x.sshiftRight 31 = if x.msb then -x else x := by
  bv_decide

-- average without overflow: compare against the wide-arithmetic spec
example (a b : BitVec 32) :
    (a &&& b) + ((a ^^^ b) >>> 1) =
      ((a.zeroExtend 33 + b.zeroExtend 33) >>> 1).truncate 32 := by
  bv_decide
```

Use it for: overflow checks, alignment tricks, branchless min/max/abs, mask arithmetic, sign extension. Model the target's exact width; when the spec needs non-wrapping arithmetic, compute it at a wider width (`zeroExtend`) and `truncate` back, as in the average example. The goal must be pure `BitVec`/`Bool` terms — no `List`, `Nat` quantifiers, or unbounded recursion. Note the verdict as PROVED (bv_decide adds `Lean.ofReduceBool` — trusts the SAT checker path; mention it in the axiom audit).

## Invariant preservation

Model the system as a state plus a step function; the invariant claim decomposes into "holds initially" and "preserved by step":

```lean
structure S where
  balance : Int
  locked  : Bool
deriving Repr, DecidableEq

inductive Op | deposit (n : Nat) | withdraw (n : Nat) | lock
def step : S → Op → S := ...
def inv (s : S) : Prop := s.balance ≥ 0

theorem inv_init : inv s₀ := by simp [inv, s₀]
theorem inv_step (s : S) (op : Op) (h : inv s) : inv (step s op) := by
  unfold inv step at *
  cases op <;> grind
```

`unfold` + `cases <;> grind` dispatches most transition systems (grind splits the `if`s and does the arithmetic). If `grind` stalls, the manual chain is `cases op <;> simp_all [inv, step] <;> split <;> simp_all <;> omega`. If `inv_step` fails, the failing case names the operation that breaks the invariant — that *is* the bug report. Sequences follow for free by induction over `List Op` (`foldl step`).

## Complexity via cost models

Lean can't observe running time, so make cost explicit: write a cost-instrumented twin returning `(result, cost)` where cost counts the operation of interest (comparisons, recursive calls, loop iterations). Keep the twin structurally identical to the model — that identity is checkable:

```lean
-- named insertSorted: bare `insert` collides with core's `Insert.insert`
def insertSorted (x : Int) : List Int → List Int
  | [] => [x]
  | y :: ys => if x ≤ y then x :: y :: ys else y :: insertSorted x ys

def insertSortedC (x : Int) : List Int → List Int × Nat
  | [] => ([x], 0)
  | y :: ys =>
    if x ≤ y then (x :: y :: ys, 1)
    else let (r, c) := insertSortedC x ys; (y :: r, c + 1)

-- twin agrees with model (rung 3 is usually easy — same recursion)
theorem insertSortedC_fst (x : Int) (l : List Int) :
    (insertSortedC x l).1 = insertSorted x l := by
  fun_induction insertSortedC x l <;> grind [insertSorted]

-- the bound, checked then proved
theorem insertSortedC_le (x : Int) (l : List Int) :
    (insertSortedC x l).2 ≤ l.length := by
  fun_induction insertSortedC x l <;> simp_all <;> omega
```

For recurrences (divide & conquer), state the recurrence as the cost function and check the closed-form bound on a range with `decide`/`native_decide`; prove by strong induction (`Nat.strong_induction_on` or `fun_induction`) only when the task demands rung 3. Worst-case inputs: search for the cost-maximizing input over a small domain with `#eval` — useful to confirm the analysis targets the true worst case.

## Core tactic cheatsheet

What's available without mathlib, roughly in the order to try:

| Tactic | Closes |
|--------|--------|
| `rfl` / `decide` / `native_decide` | definitional equality / decidable props / big decidable props |
| `simp [f, g]` | goals after unfolding definitions; `simp_all` to use hypotheses |
| `omega` | linear arithmetic over `Nat`/`Int` (the workhorse for index math) |
| `grind` | general finisher: equalities, case splits, congruence, linear arith — try it early |
| `bv_decide` | anything over `BitVec` (needs `import Std.Tactic.BVDecide`) |
| `induction x with ...` / `cases x` | structural recursion / case analysis |
| `fun_induction f a b` | induction following `f`'s own recursion — ideal for proving facts about the model's functions |
| `intro` / `constructor` / `exact` / `apply` / `funext` / `by_cases h : p` | plumbing |
| `<;>` combinator | apply next tactic to all generated goals: `cases op <;> grind` |

**Mathlib-only (unavailable — restate instead):** `ring`, `linarith`, `nlinarith`, `positivity`, `norm_num`, `field_simp`, `Finset`, `Real`, `Polynomial`. Nonlinear `Nat`/`Int` goals: expand products with `simp [Nat.mul_succ, Nat.succ_mul, Nat.left_distrib, Nat.right_distrib]` then `omega`, or try `grind` first.

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| `unknown identifier 'ring'` etc. | mathlib-only tactic — see list above |
| `failed to synthesize Decidable` | claim quantifies over an infinite type — bound it (`List.range n |>.all`) or add `deriving DecidableEq` to your types |
| `deterministic timeout` on `decide` | `set_option maxHeartbeats 1000000 in`, shrink domain, or `native_decide` |
| `maximum recursion depth` | `set_option maxRecDepth 2048 in`, or switch `decide` → `native_decide` |
| `fail to show termination` | `termination_by` a decreasing measure, or the fuel pattern (modeling.md) |
| theorem "proved" suspiciously easily | run `#print axioms` — a stray `sorry` upstream infects everything downstream |
| `#eval` panics | that's a finding: the model hit the target's panic path — check whether the target does too |
