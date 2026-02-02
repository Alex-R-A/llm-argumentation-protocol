# Argumentation Protocol

A bounded multi-agent deliberation protocol implementing structured argumentation semantics for LLM-to-LLM consultation.

**Primary implementation:** Claude Code (orchestrator) consulting external LLM CLIs (consultee). Two implementations are provided: `codex-ask` (consults Codex CLI) and `gemini-ask` (consults Gemini CLI). The protocol mechanics are LLM-agnostic; adapting to other consultees requires creating a wrapper and updating consultee-specific references (e.g., provenance tags).

## Abstract

This protocol formalizes adversarial deliberation between a primary agent (orchestrator) and a secondary agent (consultee) under epistemic constraints. The system employs attack/defense mechanics inspired by abstract argumentation frameworks, with acceptance semantics that partition claims into terminal states. Deliberation proceeds through scope-restricted phases with bounded iteration, ensuring termination while preserving coverage of raised arguments.

## Motivation

Naive LLM consultation suffers from several failure modes:

1. **Epistemic inflation** — LLM-to-LLM agreement is weak evidence due to correlated training data. Mutual reinforcement can amplify unfounded claims.
2. **Authority confusion** — Treating consultee output as authoritative bypasses critical evaluation.
3. **Scope creep** — Unbounded deliberation drifts from the original query.
4. **Sycophantic collapse** — Under pushback, LLMs may capitulate rather than defend valid positions.
5. **Silent position drift** — Context decay causes unacknowledged contradictions across iterations.

This protocol addresses each through explicit mechanisms: epistemic gates, anti-authority invariants, phase restrictions, defense obligations, and position stability checks.

## Theoretical Foundations

The protocol draws from several formal traditions:

**Abstract Argumentation Theory.** Following Dung (1995), arguments exist in attack relations. A claim under challenge must be defended or concedes defeat. The acceptance semantics (Agreed/Dismissed/Unresolved) partition the argument space, though the computation is procedural rather than fixpoint-based.

**Epistemic Constraints.** Empirical claims require verification against shared artifacts. The evidence hierarchy distinguishes execution traces (strongest), textual citations, and unverified assertions. Claims lacking grounding cannot achieve acceptance regardless of rhetorical force.

**Phased Scope Restriction.** Content introduction is progressively restricted: CONSTRUCTIVE admits new arguments; DEVELOPMENT permits extensions, defenses, and rebuttals; CRYSTALLIZATION allows defenses to open challenges and decisive evidence only. This staged restriction forces convergence by eliminating late-stage scope expansion.

## Protocol Specification

### State Space

```
S = (L, C, B, φ, n, M)

L : Ledger       — Append-only fact base with provenance tags
C : Challenges   — Map of attack relations {id → (claim, objection, status)}
B : Buckets      — Partitioned acceptance states (Agreed | Dismissed | Unresolved)
φ : Phase        — Current protocol phase ∈ {CONSTRUCTIVE, DEVELOPMENT, CRYSTALLIZATION}
n : Iteration    — Current round ∈ [1, 8]
M : SSM          — Solution Space Mapping (shape, tangents, drift signals)
```

### Ledger Provenance

Each ledger entry carries a provenance tag determining its epistemic weight:

| Tag | Source | Weight |
|-----|--------|--------|
| `user` | User-provided constraint | Authoritative; cannot be superseded |
| `verified` | Confirmed against artifact | Strong; includes file:line reference |
| `<consultee>-unverified` | Consultee claim, unverified | Hypothesis only; cannot upgrade empirical claims |
| `revision` | Position change | Requires explicit justification |

**Critical constraint:** `<consultee>-unverified` entries (e.g., `codex-unverified`, `gemini-unverified`) cannot: (a) justify upgrading empirical claims to Agreed, (b) supersede `user` or `verified` entries, (c) serve as arbitration constraints.

### Phase Transition Function

```
φ(n) = CONSTRUCTIVE     if n ≤ 2
     | DEVELOPMENT      if 3 ≤ n ≤ 5
     | CRYSTALLIZATION  if n ≥ 6
```

**Extended CONSTRUCTIVE:** Permits n=3 under two triggers:
- Coverage check finds ≥1 dispute not yet addressed
- Required stress test not yet performed

Extension borrows from DEVELOPMENT budget; total cap remains 8.

### Workflow

Execution proceeds through eight stages (after invocation check gate):

```
1. Ask        — Solution Space Mapping, then initial prompt with preamble, user question, ledger
2. Triage     — Tag points {in-scope | out-of-scope | anchor-shift-candidate}, then route
3. Evaluate   — Assign: AGREE | SKEPTICAL | REJECT | ILL-FORMED
4. Critique   — Issue challenges for SKEPTICAL/REJECT points
5. Handle     — Route: revisions → Triage, defenses → evaluate quality
6. Iterate    — Check exit conditions; increment n if valid response
7. Synthesize — Verify bucket coverage, present results
8. Arbitrate  — (Optional) Secondary verification before output
```

Stages 2-6 repeat until termination. Format failures do not increment n.

### Classification Semantics

| Classification | Meaning | Action |
|----------------|---------|--------|
| **AGREE** | Claim accepted | → Agreed bucket |
| **SKEPTICAL** | Flaw identified, defense possible | Issue challenge, standard window |
| **REJECT** | Claim wrong, one chance to rebut | Issue challenge, single round |
| **ILL-FORMED** | Unevaluable (ambiguous, not a claim) | Request clarification |

### Acceptance Semantics

| Terminal State | Conditions |
|----------------|------------|
| **Agreed** | (Initial AGREE) ∨ (defense accepted ∧ evidence gate passed) |
| **Dismissed** | Concession ∨ undefended ∨ rejection with evidence ∨ out-of-scope |
| **Unresolved** | Blocked: missing data ∨ definitional mismatch ∨ criteria divergence |

**Evidence gate for empirical claims:** `evidence_type ∈ {execution, textual}` required. Value judgments bypass gate with `evidence_type = n/a`.

### Evidence Hierarchy

Strict ordering for empirical claim verification:

1. **Execution** — Runtime output, test results, compiler diagnostics (strongest)
2. **Textual** — Verbatim citations with path:line reference
3. **Claim** — Unverified assertion (insufficient for acceptance)

### Attack/Defense Mechanics

```
Challenge types:
  SKEPTICAL → defense window + reminder on first drop
  REJECT    → single defense round, terminal on failure

Defense evaluation:
  Referenced + valid   → status := defended, evaluate quality
  Unreferenced (1st)   → status := dropped, send reminder
  Unreferenced (2nd)   → status := undefended → Dismissed
  Explicit concession  → status := conceded → Dismissed
```

### Bias Calibration

The protocol includes mechanisms against evaluation bias:

**Calibration principle.** Apply identical skepticism to consultee proposals as to self-generated ideas. External origin is not evidence for or against validity.

**Position stability check.** Before finalizing any classification:
1. Have I taken a position on this point before?
2. Does current position contradict previous position?

Contradiction without explicit acknowledgment ("Revising from X to Y because...") is prohibited. Acknowledged revisions trigger ledger entry with `revision` tag; unacknowledged drift maintains original position.

**Anti-sycophancy guard.** If consultee contradicts its earlier position without acknowledgment, challenge with citation: "Iteration 2 you claimed X, now you claim ¬X. Reconcile."

### Arbitration (Optional)

Before presenting output, invoke secondary verification:

**Triggers:** (a) 2+ unresolved items, (b) early unanimous lacking evidence, (c) high-stakes decision, (d) user request.

**Prompt:** Question + ledger + buckets, no attribution. "Are agreed points well-supported? Dismissals justified? Unresolved genuinely blocked?"

Flags reduce confidence only. ≥50% flagged → present with warning or re-examine.

## Termination Conditions

The protocol terminates under any of:

1. **Convergence** — No open challenges ∧ scope stable (no new points, disputed list unchanged)
2. **Iteration bound** — n = 8 reached
3. **Early exit (trivial)** — Question factual, resolved by iter 2
4. **Early exit (quality)** — Consultee unable to produce structured responses after retry

**Deadlock classification (3+ rounds on same point):**
- Missing empirical data → route to Blocked, surface question to user
- Definitional mismatch → clarify terms, retry once
- Criteria divergence → surface tradeoff, let user choose

## Invariants

Properties that hold throughout execution:

1. **Anti-authoritarianism** — Consultee output is never accepted without evaluation
2. **Anchor preservation** — Original query remains primary until explicit user consent to reframe
3. **Epistemic gate** — Empirical claims cannot achieve Agreed via unverified assertions
4. **Defense obligation** — Challenged points must be defended by ID or are procedurally dismissed
5. **Provenance integrity** — Ledger tags cannot be upgraded without verification

## Complexity

| Measure | Bound | Notes |
|---------|-------|-------|
| Iterations | O(1) | Constant bound of 8 |
| Challenges | O(k) per iteration | k = points under dispute |
| State | O(\|L\| + \|C\| + \|M\|) | Ledger entries + challenge records + SSM |
| Messages | ≥2n | Request/response pairs; retries on format failure add extra |

## Dependencies

| Dependency | Purpose |
|------------|---------|
| [Claude Code CLI](https://github.com/anthropics/claude-code) | Orchestrator agent (executes skill) |
| [Codex CLI](https://github.com/openai/codex) | Consultee for `codex-ask` skill |
| [Gemini CLI](https://github.com/google-gemini/gemini-cli) | Consultee for `gemini-ask` skill |

Claude Code must be installed. Install and authenticate the consultee CLI(s) you intend to use.

## Usage

Implemented as Claude Code skills. The orchestrating agent loads the skill specification and executes deliberation against the consultee CLI via the corresponding wrapper script.

| Skill | Consultee | Wrapper |
|-------|-----------|---------|
| `codex-ask` | Codex CLI | `codex-wrapper.sh` |
| `gemini-ask` | Gemini CLI | `gemini-wrapper.sh` |

**Invocation:** Load skill, pose question. Protocol executes automatically.

**Modes:**

| Mode | Behavior |
|------|----------|
| Standard | Full protocol with state persistence to `~/.claude/skills/<skill>/deliberations/` |
| Minimal | Disables arbitration and stress testing; retains phases, ledger, challenge tracking |
| Quick | 2-iteration max, stateless, no SSM or challenge tracking; for simple binary decisions |

### Deliberation Flows

The first prompt's framing is open. The orchestrator chooses it, which determines the deliberation flow:

| Framing | Flow |
|---------|------|
| "How should we do X?" | Consultee proposes → Orchestrator evaluates |
| "Critique this design: [design]" | Orchestrator proposes → Consultee evaluates |
| "I think A, argue for B" | Devil's advocate / steelman |
| "Here's partial solution, fill gaps" | Collaborative completion |
| "Compare approaches A vs B vs C" | Joint comparative analysis |
| "I've analyzed X, validate my reasoning" | Verification / sanity check |
| "User wants X, I think Y, what's right?" | Orchestrator as participant with position |
| "Here are 3 stakeholder views, synthesize" | Multi-perspective arbitration |
| "Attack this design, I'll defend" | Red team exercise |
| "Let's both propose solutions, then evaluate" | Parallel ideation → mutual critique |

The protocol mechanics (phases, challenges, evidence gates) apply regardless of framing. The framing determines who proposes first and the adversarial stance, not the rigor of evaluation.

## Known Issues

### Codebase scanning overhead (Codex)

By default, Codex scans the current working directory for context. For abstract/theoretical questions unrelated to local code, this adds unnecessary overhead.

**Solution:** Use `-C /tmp` flag to set workdir to an empty directory:

```bash
codex e --sandbox read-only --skip-git-repo-check -C /tmp - <<< "Your abstract question"
```

Note: Using stdin (`<<<`) avoids escaping issues with special characters in prompts.

**When to use:** Abstract design questions, theoretical deliberations not referencing local files, general knowledge queries.

**When NOT to use:** Deliberations where automatic codebase context scanning is valuable. File access via absolute paths still works regardless of `-C` flag.

The wrapper does not use `-C /tmp` by default to preserve automatic context scanning for code-related deliberations.

### Response parsing

Both wrappers parse CLI stdout rather than using structured output schemas. Rationale: session ID and response boundaries are CLI format (not LLM-generated), schema enforcement depends on LLM compliance (which can break under complex reasoning), and parsing is simple (sed/awk, no dependencies).

### Model selection

Each wrapper has a default model configured. Edit the `MODEL` variable in the wrapper script to change it. Reasoning-optimized models typically perform better than coding-optimized models for deliberation tasks.

### Session continuity

Both wrappers support session continuity: `new` starts a session, `resume` continues it. This enables multi-turn deliberation with context preserved across iterations.

### Background task completion notifications

After deliberation concludes and output is presented, background task completion events may appear in the terminal. These notifications are cosmetic artifacts of the async execution model and do not affect deliberation results. They can be safely ignored.

## Further Reading

For a deeper explanation of how the protocol works, including LLM-specific design considerations and the reasoning behind each mechanism, see [Protocol Explained for Humans](PROTOCOL-EXPLAINED-FOR-HUMANS.md).
