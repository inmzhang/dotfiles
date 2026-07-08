---
name: lean-reasoning
description: Use Lean 4 as a machine-checked intermediate language for reasoning. Formalize the reasoning target (code in any language, an algorithm, a spec, a mathematical claim) into Lean 4, verify the reasoning against the Lean compiler, then translate the verified result back to the target language. Use this whenever a task needs rigorous reasoning where a wrong answer would be costly and plausible-looking argument is not enough — verifying code correctness, hunting subtle logic bugs (off-by-one, boundary, overflow, wraparound), proving a refactor or optimization is truly equivalent to the original over ALL inputs (not just tested ones), analyzing algorithm complexity exactly, checking that an invariant holds across every state or operation sequence, verifying bit-twiddling and overflow tricks, or proving theorems — especially when the input domain is too large to brute-force or the reasoning is the kind that fools careful people. Reach for it even if the user never mentions Lean, and even when you think you already know the answer — the point is machine-checked certainty. Trigger on phrases like "is this correct", "prove this", "verify", "are these equivalent", "does this always hold", "find the bug in this logic", "complexity of", "does this invariant hold", "is it safe to replace X with Y", or an explicit /lean-reasoning.
---

# Lean Reasoning

Reason through a machine-checked roundtrip: **target → Lean 4 → verified reasoning → target**.

Why this works: natural-language reasoning about code and algorithms can drift — a plausible-sounding argument survives even when wrong. Lean 4 reasoning cannot: the compiler rejects type errors, `decide` refutes false finite claims, and a theorem that compiles without `sorry` is *true*. Formalizing the target converts "I believe this is correct" into a checkable artifact, and the compiler becomes the test suite for your reasoning itself.

The guarantee has one honest gap: the translation between the target and Lean is not machine-checked. Everything in this skill is designed to keep that gap small, visible, and stated in the final answer.

## Prerequisites

Check the toolchain once per session:

```bash
lean --version   # Lean 4.x via elan
```

Work with **single files and core Lean only** — no `lake` project, no mathlib. A single-file compile takes ~2 seconds, which is what makes the tight verify loop viable. Mathlib would add `ring`/`linarith` and a big lemma library, but costs a multi-GB project setup; core Lean's `simp`, `omega`, `grind`, `decide`, and `bv_decide` cover almost all reasoning about programs. If a goal genuinely needs mathlib, say so and ask before setting it up.

## Artifacts

Write all Lean files under the project-local `./tmp/` directory (create it if missing):

```
./tmp/lean-reasoning/<task-slug>/
├── Model.lean      # formalization + claims + proofs (single file by default)
└── NOTES.md        # only if fidelity notes outgrow the comment block
```

Project-local `tmp/` keeps artifacts discoverable and lets the user inspect or re-run them. One file is the default; split only when a model is reused across several claim files.

## The Roundtrip

### Step 1 — Scope the reasoning kernel

Formalize the *logic being reasoned about*, not the program around it. From a 200-line function, extract the loop, the index arithmetic, the state transition — the part where the question actually lives. I/O, logging, and plumbing stay out of the model. A small faithful model beats a large sloppy one: every line of model is a line of translation gap.

### Step 2 — Formalize (target → Lean)

Write `Model.lean` mirroring the target's structure as closely as Lean allows — same names, same operation order, same branching. The closer the mirror, the smaller the translation gap. Lean's `Id.run do` with `let mut` and `for` loops lets imperative code translate nearly line-by-line; see [references/modeling.md](references/modeling.md) for the pattern catalog (machine integers, mutation, early return, null, exceptions, floats, termination).

Open the file with a **fidelity notes** comment block recording every deliberate deviation:

```lean
/- Fidelity notes:
   - `i32` modeled as `Int` (idealized, no overflow). Overflow is
     checked separately with `BitVec 32` in section 3.
   - `panic!` on empty input modeled as `Option.none`.
-/
```

Compile immediately and after every addition:

```bash
lean ./tmp/lean-reasoning/<task-slug>/Model.lean
```

Fix all errors before stating any claims — at this stage a compiler error means the *model* is wrong, and claims about a wrong model are worthless.

### Step 3 — Reason (claims against the compiler)

State each question about the target as a Lean claim, then push it up the assurance ladder as far as the task needs:

| Rung | Form | What it buys |
|------|------|--------------|
| 1. Spot test | `#eval f 3` | Sanity; catches gross modeling errors |
| 2. Finite check | `example : (List.range 1000).all (fun n => p n) := by decide` | Exhaustive over the domain checked — refutes or strongly confirms |
| 3. Full proof | `theorem t : ∀ n, p n := by ...` | True, unconditionally |

Not every claim needs rung 3. A bug hunt is *done* at rung 2 when a counterexample falls out; an equivalence claim guarding a refactor deserves rung 3 (or an explicit finite-check verdict). Climb until the answer is decisive, then stop.

**Stop at decisive — a full proof is not the goal, the answer is.** The most expensive mistake here is over-climbing: sinking effort into a `∀`-proof of something a finite check already settled. Concrete brakes:

- Once a counterexample is found, the claim is **REFUTED** — you are done with it. Do not also prove the exact boundary of the agreement domain unless the user needs it; a finite check of "and they agree on everything else I tried" is enough.
- For any type with a bounded value space that Lean can enumerate — `BitVec 8/16/32`, small `Nat` ranges, small structures — reach for `decide`/`native_decide`/`bv_decide` (seconds, and it covers *every* value) before writing an inductive proof by hand. A hand-rolled invariant proof is the last resort, not the first.
- Facts like "this loop never terminates for `v > k`" or "this recursion is unbounded" rarely need a machine proof for a reasoning task — state them from the finite evidence and the code, and say so, rather than spending the session proving them. If the user explicitly wants the unconditional theorem, then climb; otherwise the finite verdict is the deliverable.

The single skill run that most nearly failed its purpose spent 88 tool calls and half an hour proving a non-termination lemma the finite checks had already made obvious. Don't be that run.

For bug hunting, run the search direction too — ask the compiler to *find* the failing input:

```lean
#eval (List.range 1000).filter (fun n => original n ≠ optimized n) |>.take 5

```

A non-empty result is a concrete, reproducible counterexample to hand back to the user. See [references/techniques.md](references/techniques.md) for counterexample search over pairs/structures, equivalence proofs, cost-model complexity analysis, invariant preservation, bit-level verification with `bv_decide`, and the core-tactic cheatsheet (`grind` and `omega` close most program-reasoning goals).

### Step 4 — Audit the axioms

`sorry` compiles with only a warning, so a green compile alone does not mean "proved". Before reporting, audit every claim you intend to cite:

```lean
#print axioms myTheorem
```

- Standard axioms only (`propext`, `Classical.choice`, `Quot.sound`, or fewer) → fully proved.
- `sorryAx` listed → **not proved**; report the claim as unproven, never as verified.
- `Lean.ofReduceBool` → used `native_decide`; proof trusts the Lean compiler backend. Fine for reasoning tasks, but say so.

### Step 5 — Roundtrip back (Lean → target)

Translate the verified result — the fix, the equivalent optimized algorithm, the tightened invariant — back into the target language, preserving the structure the proof validated. Then report using this verdict vocabulary, one line per claim:

- **PROVED** — theorem compiles, axiom audit clean.
- **FINITE-CHECKED (domain)** — exhaustively verified on the stated domain, e.g. "all n < 10⁶", "all `BitVec 32`".
- **REFUTED** — counterexample found; give the concrete input, its behavior in the model, and (when reproducible) confirm it against the real target.
- **TESTED** — spot checks only; weakest verdict, flag it as such.
- **UNPROVEN** — stated but not established (`sorry` remains); never blend into the verified results.

Close with the artifact path and one sentence on the translation gap — what the model idealized (from the fidelity notes) and therefore what the verification does and does not cover in the real target.

## Compile-loop discipline

- Recompile after every meaningful addition; never batch up many claims untested. The 2-second loop is the whole point.
- Compiler errors during Step 3 are *findings*, not obstacles — a type error in a claim often reveals a real ambiguity in the informal question. Surface those.
- A heavy `decide`/`native_decide` hitting `maximum recursion depth` or `deterministic timeout`: raise limits locally with `set_option maxHeartbeats 1000000 in` / `set_option maxRecDepth 2048 in`, shrink the domain, or switch `decide` → `native_decide`.
- Termination checker rejects a recursive definition: add `termination_by`, or use the fuel pattern (modeling.md). Avoid `partial def` when the function must be reasoned about — it is opaque to proofs and to `decide`.
- `unknown identifier 'ring'` / `linarith` / `nlinarith` / `Finset` / `Real` → mathlib-only; restate with core primitives (`Nat`, `Int`, `List`, `Array`, `BitVec`) and close goals with `simp`, `omega`, or `grind`.

## When not to use this

Skip the roundtrip when the question is answerable by direct inspection or a quick run of the actual code — formalization pays off only when the reasoning itself is error-prone (quantifiers, boundary conditions, equivalence, invariants, arithmetic). Skip floats-dominated numerics (Lean `Float` supports `#eval` but not `decide`; model gaps get large) unless the question is really about exact/integer structure underneath. For deep Lean proof work inside an existing Lean project, prefer the dedicated `lean4` plugin skill if installed — this skill is about the roundtrip method, not mathlib engineering.
